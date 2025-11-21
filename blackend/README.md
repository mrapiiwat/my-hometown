## การใช้งาน Python Virtual Environment และการจัดการ Dependencies

### สร้าง Virtual Environment

```bash
python3 -m venv venv  # สร้าง virtual environment
```

### การเข้าใช้งาน Virtual Environment

- **Windows**
    ```bash
    venv\Scripts\activate
    ```
- **Mac/Linux**
    ```bash
    source venv/bin/activate
    ```

### การออกจาก Virtual Environment

```bash
deactivate
```

---

### การจัดการ Dependencies

- **บันทึก dependencies ปัจจุบันลงในไฟล์ `requirements.txt`**
    ```bash
    pip freeze > requirements.txt
    ```

- **ติดตั้ง dependencies จากไฟล์ `requirements.txt`**
    ```bash
    pip install -r requirements.txt
    ```
