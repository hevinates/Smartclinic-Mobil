from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pdfplumber
import fitz  # PyMuPDF
import io
import re
import json
from datetime import datetime
from pathlib import Path

app = FastAPI()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_FILE = Path("tests.json")

def load_all_tests():
    if DATA_FILE.exists():
        return json.loads(DATA_FILE.read_text(encoding="utf-8"))
    return {}

def save_test(date, results):
    data = load_all_tests()
    data[date] = results
    DATA_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

@app.post("/api/upload/pdf")
async def upload_pdf(file: UploadFile = File(...)):
    content = await file.read()
    pdf_stream = io.BytesIO(content)

    # 1️⃣ pdfplumber ile metni çıkar
    all_text = ""
    with pdfplumber.open(pdf_stream) as pdf:
        for page in pdf.pages:
            all_text += page.extract_text() or ""

    # 2️⃣ fitz (PyMuPDF) ile metni çıkar (bazı PDF'lerde metin grafikte olabilir)
    pdf_doc = fitz.open(stream=content, filetype="pdf")
    for page in pdf_doc:
        all_text += "\n" + (page.get_text("text") or "")

    # 3️⃣ tarih bul
    date_match = re.search(r"(?i)tarih[: ]+(\d{1,2}\.\d{1,2}\.\d{4})", all_text)
    test_date = date_match.group(1) if date_match else datetime.now().strftime("%d.%m.%Y")

    # 4️⃣ tabloyu pdfplumber ile ayrıştır
    results = []
    with pdfplumber.open(io.BytesIO(content)) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            for table in tables:
                for row in table:
                    if not row or len(row) < 5:
                        continue

                    tahlil = (row[1] or "").strip()
                    sonuc = (row[2] or "").strip().replace(",", ".")
                    ref = (row[4] or "").strip().replace(",", ".")
                    is_out = False

                    # başlık veya geçersiz satırları atla
                    if (
                        not tahlil
                        or not sonuc
                        or not ref
                        or tahlil.lower().startswith("tahlil")
                        or sonuc.lower().startswith("sonuç")
                        or ref.lower().startswith("referans")
                    ):
                        continue

                    # referans dışı değer kontrolü
                    try:
                        if "-" in ref:
                            low, high = map(float, ref.split("-"))
                            val = float(sonuc)
                            if val < low or val > high:
                                is_out = True
                    except:
                        pass

                    results.append({
                        "name": tahlil,
                        "result": sonuc,
                        "range": ref,
                        "isOutOfRange": is_out
                    })

    # JSON’a kaydet
    save_test(test_date, results)

    return {"date": test_date, "results": results}

@app.get("/api/tests")
def list_tests():
    data = load_all_tests()
    return {"dates": list(data.keys())}

@app.get("/api/tests/{date}")
def get_test_by_date(date: str):
    data = load_all_tests()
    return {"date": date, "results": data.get(date, [])}
