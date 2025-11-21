import os
import glob
from dotenv import load_dotenv

from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.chat_models import ChatOpenAI
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain.schema import Document

load_dotenv()

DATA_DIR = os.getenv("DATA_DIR", "data")
FAISS_INDEX_DIR = os.getenv("FAISS_INDEX_DIR", "faiss_index")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4o-mini")


class RAGEngine:
    def __init__(self, rebuild_index: bool = False):
        self.embeddings = OpenAIEmbeddings(model=EMBEDDING_MODEL)
        self.model = ChatOpenAI(model=LLM_MODEL, temperature=0)
        self.index = None
        os.makedirs(FAISS_INDEX_DIR, exist_ok=True)

        if rebuild_index or not self._index_exists():
            self._build_index()
        else:
            self._load_index()

    def _index_exists(self) -> bool:
        return any(os.scandir(FAISS_INDEX_DIR))

    def _load_documents(self):
        docs = []
        patterns = [os.path.join(DATA_DIR, "*.md"), os.path.join(DATA_DIR, "*.txt")]
        for pattern in patterns:
            for path in glob.glob(pattern):
                with open(path, "r", encoding="utf-8") as f:
                    text = f.read()
                docs.append(Document(page_content=text, metadata={"source": os.path.basename(path)}))
        return docs

    def _build_index(self):
        raw_docs = self._load_documents()
        if not raw_docs:
            raise ValueError(f"No documents found in {DATA_DIR}. Put .md or .txt files there.")
        splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        docs = splitter.split_documents(raw_docs)
        self.index = FAISS.from_documents(docs, self.embeddings)
        self.index.save_local(FAISS_INDEX_DIR)

    def _load_index(self):
        self.index = FAISS.load_local(
            FAISS_INDEX_DIR,
            self.embeddings,
            allow_dangerous_deserialization=True
        )

    def ask(self, question: str, k: int = 4) -> dict:
        results = self.index.similarity_search_with_score(question, k=k)
        docs = [r[0] for r in results]
        scores = [float(r[1]) for r in results] 
        context_text = "\n\n".join([f"SOURCE: {d.metadata.get('source','unknown')}\n\n{d.page_content}" for d in docs])

        prompt = f"""
                You are an assistant that answers questions **only** using the context below.
                Be concise and include minimal necessary explanation.
                --- CONTEXT START ---
                {context_text}
                --- CONTEXT END ---

                Question: {question}
                Answer:
                """
        response = self.model.invoke(prompt)
        if hasattr(response, "content"):
            answer_text = response.content
        elif isinstance(response, str):
            answer_text = response
        else:
            try:
                answer_text = response.generations[0][0].text
            except Exception:
                answer_text = str(response)

        sources = [d.metadata.get("source", "") for d in docs]
        return {"answer": answer_text.strip(), "sources": sources, "scores": scores}