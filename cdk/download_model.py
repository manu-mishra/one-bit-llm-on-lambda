#!/usr/bin/env python3
"""
BitNet Model Downloader
Downloads the BitNet model from Hugging Face with proper authentication.
"""

import os
import sys
from pathlib import Path
from huggingface_hub import hf_hub_download, login
from huggingface_hub.utils import HfHubHTTPError
import getpass

def authenticate_huggingface():
    """Authenticate with Hugging Face with retry loop."""
    # Check if already authenticated first
    try:
        from huggingface_hub import HfApi
        api = HfApi()
        user_info = api.whoami()
        if user_info:
            print(f"✅ Already authenticated as: {user_info['name']}")
            return True
    except Exception:
        pass
    
    # Try environment token first
    token = os.getenv('HUGGINGFACE_HUB_TOKEN')
    if token:
        try:
            login(token=token, add_to_git_credential=True)
            print("✅ Successfully authenticated with environment token")
            return True
        except Exception as e:
            print(f"❌ Environment token failed: {e}")
    
    # Interactive token input with retry loop
    max_attempts = 3
    for attempt in range(max_attempts):
        print(f"\n🔐 Hugging Face Authentication Required (Attempt {attempt + 1}/{max_attempts})")
        print("Please get your token from: https://huggingface.co/settings/tokens")
        print("You need a token with 'Read' permissions.")
        
        token = getpass.getpass("Enter your Hugging Face token (or 'quit' to exit): ").strip()
        
        if token.lower() == 'quit':
            print("❌ Authentication cancelled by user")
            return False
        
        if not token:
            print("❌ No token provided, please try again")
            continue
        
        try:
            login(token=token, add_to_git_credential=True)
            print("✅ Successfully authenticated with Hugging Face")
            return True
        except Exception as e:
            print(f"❌ Authentication failed: {e}")
            if attempt < max_attempts - 1:
                print("Please check your token and try again...")
            else:
                print("❌ Maximum authentication attempts reached")
    
    return False

def download_bitnet_model(model_dir):
    """Download the BitNet model from the specified repository."""
    repo_id = "microsoft/bitnet-b1.58-2B-4T-gguf"
    filename = "ggml-model-i2_s.gguf"
    
    print(f"📥 Downloading BitNet model from {repo_id}...")
    print("This may take several minutes (~750MB download)...")
    
    try:
        # Create directory if it doesn't exist
        os.makedirs(model_dir, exist_ok=True)
        
        # Download the model
        downloaded_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=model_dir,
            local_dir_use_symlinks=False
        )
        
        # Verify download
        model_path = os.path.join(model_dir, filename)
        if os.path.exists(model_path):
            file_size = os.path.getsize(model_path)
            if file_size > 1000000:  # Should be > 1MB (actual model is ~750MB)
                print(f"✅ Model downloaded successfully from {repo_id}")
                print(f"   File path: {model_path}")
                print(f"   File size: {file_size / (1024*1024):.1f} MB")
                return True
            else:
                print(f"❌ Downloaded file seems too small: {file_size} bytes")
                return False
        else:
            print("❌ Model file not found after download")
            return False
            
    except HfHubHTTPError as e:
        if e.response.status_code == 401:
            print("❌ Authentication failed. Please check your token.")
            print("   Get a token from: https://huggingface.co/settings/tokens")
        elif e.response.status_code == 403:
            print("❌ Access denied. You may need to accept the model's license.")
            print(f"   Visit: https://huggingface.co/{repo_id}")
        elif e.response.status_code == 404:
            print(f"❌ Repository {repo_id} not found.")
            print("   Please check if the repository exists and is accessible.")
        else:
            print(f"❌ HTTP Error: {e}")
        return False
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return False

def main():
    """Main function."""
    print("🚀 BitNet Model Downloader")
    print("=" * 50)
    
    # Get project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    model_dir = project_root / "temp" / "models" / "BitNet-b1.58-2B-4T"
    
    print(f"📁 Model will be saved to: {model_dir}")
    
    # Check if model already exists
    model_file = model_dir / "ggml-model-i2_s.gguf"
    if model_file.exists() and model_file.stat().st_size > 1000000:
        print("✅ Model already exists and appears valid")
        print(f"   File size: {model_file.stat().st_size / (1024*1024):.1f} MB")
        return True
    
    # Authenticate with Hugging Face
    if not authenticate_huggingface():
        print("❌ Failed to authenticate with Hugging Face")
        print("\n💡 To fix this:")
        print("   1. Go to https://huggingface.co/settings/tokens")
        print("   2. Create a token with 'Read' permissions")
        print("   3. Run this script again")
        return False
    
    # Download the model
    if download_bitnet_model(str(model_dir)):
        print("\n🎉 Model download completed successfully!")
        print("You can now deploy the Lambda function.")
        return True
    else:
        print("\n❌ Model download failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
