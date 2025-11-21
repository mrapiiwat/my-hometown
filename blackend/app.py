from flask import Flask, request, jsonify
from rag import RAGEngine

app = Flask(__name__)
rag = RAGEngine(rebuild_index=True) 

@app.route("/ask", methods=["POST"])
def ask():
    data = request.json
    question = data.get("question", "")
    if not question:
        return jsonify({"error": "No question provided"}), 400
    response = rag.ask(question)
    return jsonify(response)

if __name__ == "__main__":
    app.run(debug=True, port=5000)