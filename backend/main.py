from fastapi import FastAPI, HTTPException, Header
from fastapi.responses import FileResponse
from pydantic import BaseModel
import os
import uuid
from security import license_manager
from services.ai_generator import AIGenerator

app = FastAPI(title="Video Tuyên Truyền Lai Hòa API")

class VideoRequest(BaseModel):
    topic: str
    duration: int = 60

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Video Tuyên Truyền Lai Hòa API is running"}

@app.post("/generate-video")
async def generate_video(request: VideoRequest, x_license_key: str = Header(...)):
    if not license_manager.verify_license(x_license_key):
        raise HTTPException(status_code=403, detail="Invalid or expired license key")
        
    try:
        # Generate a unique filename
        filename = f"video_{uuid.uuid4().hex[:8]}.mp4"
        video_path = await AIGenerator.process_video_pipeline(request.topic, output_filename=filename)
        
        # Return the actual file as response
        # In a real app with Drive upload, we'd upload and return the link, 
        # but for this MVP we return the binary file directly.
        return FileResponse(
            path=video_path, 
            media_type="video/mp4", 
            filename=filename,
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
