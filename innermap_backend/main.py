# main.py (Python Backend Kök Dizini)

import os
import uvicorn
import whisper
import tempfile
import json
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from dotenv import load_dotenv

# .env dosyasını yükle (PORT ve HOST için)
load_dotenv()

# Pydantic Modeli: Yazılı metin girişi için veri yapısı
class TextRequest(BaseModel):
    text: str

# FastAPI uygulamasını başlat
app = FastAPI()

# Global olarak Whisper modelini yükle
# 'small' modelini kullanmak önerilir. Daha büyük modeller çok yavaş olabilir.
model = None
try:
    print("Whisper model yükleniyor (small)...")
    # Cihazınızın GPU'su varsa 'cuda' kullanın, yoksa varsayılan CPU'dur.
    model = whisper.load_model("small") 
    print("Whisper model başarıyla yüklendi.")
except Exception as e:
    print(f"Whisper yüklenirken hata: {e}. Model transkripsiyon için kullanılamayacak.")
    # Model yüklenemezse bile API'nin diğer endpoint'leri çalışmaya devam eder.


@app.get("/")
def read_root():
    """API'nin durumunu kontrol etmek için basit bir uç nokta."""
    return {"message": "Innermap Backend Çalışıyor", "whisper_status": "Ready" if model else "Error"}

# --- 1. Hafta Ana Hedefi: Ses Transkripsiyonu ---
@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Flutter'dan gelen ses dosyasını alır, Whisper ile metne çevirir ve döndürür.
    Flutter'dan gelen parametre adı 'file' olmalıdır.
    """
    if model is None:
        raise HTTPException(
            status_code=503, 
            detail="Whisper model servisi hazır değil. Lütfen logları kontrol edin."
        )

    # Geçici bir dosya oluşturma
    temp_dir = tempfile.gettempdir()
    # Yüklenen dosyanın adını kullanarak geçici yolu oluştur
    temp_file_path = os.path.join(temp_dir, file.filename)
    
    # Gelen dosya içeriğini geçici dosyaya yazma
    try:
        content = await file.read()
        with open(temp_file_path, "wb") as f:
            f.write(content)

        print(f"[LOG] Dosya kaydedildi: {temp_file_path}")

        # Whisper ile transkripsiyon yapma
        print("[LOG] Transkripsiyon başlatılıyor...")
        result = model.transcribe(temp_file_path)
        transcript = result["text"]
        print(f"[LOG] Transkripsiyon tamamlandı: {transcript[:50]}...")

        # Başarılı JSON yanıtı döndürme
        return JSONResponse(content={
            "success": True,
            "transcript": transcript, # Flutter HomeScreen bu anahtarı bekliyor
            "language": result.get("language", "unknown")
        })

    except Exception as e:
        print(f"[ERROR] Transkripsiyon hatası: {e}")
        raise HTTPException(status_code=500, detail=f"Sunucu hatası: {e}")
    finally:
        # Geçici dosyayı silme
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

# --- Metin Analiz Simülasyonu ---
@app.post("/analyze_text")
async def analyze_text(request: TextRequest):
    """
    Flutter'dan gelen yazılı metni alır ve analiz simülasyonu yapar.
    (2. Hafta'da buraya gerçek LLM entegrasyonu gelecek)
    """
    
    if not request.text or len(request.text) < 5:
        return JSONResponse(content={
            "success": False,
            "analysis": "Geçerli metin girilmedi.",
        })
        
    print(f"[LOG] Analiz için metin alındı: {request.text[:50]}...")
    
    # Simülasyon: Metni analiz edilmiş gibi gösteren bir metin döndür
    analyzed_text = f"Analiz simülasyonu tamamlandı: Bu fikir, 'Girişimcilik', 'MVP Geliştirme' ve 'Yapay Zeka' ana kavramlarına ayrıldı. Metin: '{request.text}'"

    return JSONResponse(content={
        "success": True,
        "analysis": analyzed_text, # Flutter HomeScreen bu anahtarı bekliyor
        "source": "text_input"
    })


if __name__ == "__main__":
    # .env dosyasından HOST ve PORT değerlerini okur, bulamazsa varsayılanı kullanır
    host = os.getenv("HOST", "0.0.0.0") 
    port = int(os.getenv("PORT", 8000))
    
    # Uvicorn'u başlatma (reload=True geliştirme sırasında otomatik yeniden başlatma sağlar)
    uvicorn.run("main:app", host=host, port=port, reload=True)