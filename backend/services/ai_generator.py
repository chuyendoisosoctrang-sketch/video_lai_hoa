import os
import subprocess
import edge_tts
import google.generativeai as genai
import tempfile
import asyncio

# Setup Gemini API (Make sure GEMINI_API_KEY is available in env)
genai.configure(api_key=os.environ.get("GEMINI_API_KEY", "MOCK_KEY"))
model = genai.GenerativeModel('gemini-1.5-flash') # Using free tier friendly model

class AIGenerator:
    @staticmethod
    async def generate_script(topic: str) -> str:
        """Call Gemini to generate a short script"""
        if os.environ.get("GEMINI_API_KEY", "MOCK_KEY") == "MOCK_KEY":
            # Fallback for testing when no key is provided
            return f"Đây là video tuyên truyền về chủ đề {topic}. Hãy chung tay hành động vì một tương lai tươi sáng hơn."
            
        prompt = f"Viết một kịch bản ngắn (khoảng 30-50 từ) để làm video tuyên truyền về chủ đề: {topic}. Ngôn ngữ: Tiếng Việt, giọng điệu: truyền cảm, trang trọng. Không bao gồm các dòng chỉ dẫn hành động."
        response = await asyncio.to_thread(model.generate_content, prompt)
        return response.text.strip()

    @staticmethod
    async def generate_audio(text: str, output_path: str, voice: str = "vi-VN-HoaiMyNeural"):
        """Use edge-tts to generate voice audio"""
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(output_path)

    @staticmethod
    def generate_video(audio_path: str, output_path: str):
        """Use ffmpeg to combine a generated background with the audio"""
        # Create a blank video with teal color background, matching audio duration
        cmd = [
            "ffmpeg",
            "-y", # Overwrite
            "-f", "lavfi",
            "-i", "color=c=teal:s=1280x720",
            "-i", audio_path,
            "-c:v", "libx264",
            "-preset", "veryfast", # Fast encoding to save CPU
            "-crf", "28", # Decent compression
            "-c:a", "aac",
            "-b:a", "128k",
            "-shortest", # End video when audio ends
            output_path
        ]
        
        # We use run and check=True so it raises exception on failure
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    @staticmethod
    async def process_video_pipeline(topic: str, output_filename: str = "output.mp4") -> str:
        """Main pipeline tying it all together. Returns the path to the video file."""
        # Use temp directory for intermediate files
        temp_dir = tempfile.gettempdir()
        audio_path = os.path.join(temp_dir, f"audio_{hash(topic)}.mp3")
        video_path = os.path.join(temp_dir, output_filename)
        
        try:
            # 1. Generate Script
            script_text = await AIGenerator.generate_script(topic)
            
            # 2. Generate Audio
            await AIGenerator.generate_audio(script_text, audio_path)
            
            # 3. Generate Video
            # Run blocking ffmpeg call in a thread
            await asyncio.to_thread(AIGenerator.generate_video, audio_path, video_path)
            
            return video_path
        finally:
            # Clean up intermediate audio
            if os.path.exists(audio_path):
                os.remove(audio_path)
