import pytest
from unittest.mock import patch, AsyncMock
from services.ai_generator import AIGenerator

@pytest.mark.asyncio
async def test_generate_script_with_mock_key(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "MOCK_KEY")
    script = await AIGenerator.generate_script("test topic")
    assert "tuyên truyền" in script
    assert "test topic" in script

@pytest.mark.asyncio
async def test_generate_script_with_real_key(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "REAL_KEY")
    
    # Mock Google Generative AI
    with patch("services.ai_generator.model.generate_content") as mock_gen:
        mock_gen.return_value.text = "Generated script text"
        script = await AIGenerator.generate_script("test topic")
        assert script == "Generated script text"

@pytest.mark.asyncio
async def test_generate_audio():
    with patch("services.ai_generator.edge_tts.Communicate.save", new_callable=AsyncMock) as mock_save:
        await AIGenerator.generate_audio("test text", "output.mp3")
        mock_save.assert_called_once_with("output.mp3")

def test_generate_video():
    with patch("services.ai_generator.subprocess.run") as mock_run:
        AIGenerator.generate_video("audio.mp3", "output.mp4")
        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        assert "ffmpeg" in args
        assert "audio.mp3" in args
        assert "output.mp4" in args

@pytest.mark.asyncio
async def test_process_video_pipeline(monkeypatch):
    # Mock the static methods to avoid actual processing
    async def mock_script(topic):
        return "mock script"
    async def mock_audio(text, output_path, voice="vi-VN-HoaiMyNeural"):
        pass
    def mock_video(audio_path, output_path):
        # Create a dummy file to simulate success
        with open(output_path, "w") as f:
            f.write("mock video")

    monkeypatch.setattr(AIGenerator, "generate_script", mock_script)
    monkeypatch.setattr(AIGenerator, "generate_audio", mock_audio)
    monkeypatch.setattr(AIGenerator, "generate_video", mock_video)

    video_path = await AIGenerator.process_video_pipeline("topic", "test_out.mp4")
    assert "test_out.mp4" in video_path
    
    # Read the dummy file
    with open(video_path, "r") as f:
        assert f.read() == "mock video"
