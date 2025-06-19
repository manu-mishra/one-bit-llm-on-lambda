import json
import subprocess
import threading
import time
import requests
import os
import signal
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set OpenMP environment variables to completely disable shared memory usage
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['OMP_THREAD_LIMIT'] = '1'
os.environ['OMP_DYNAMIC'] = 'FALSE'
os.environ['OMP_PROC_BIND'] = 'FALSE'
os.environ['OMP_PLACES'] = 'threads'
os.environ['OMP_WAIT_POLICY'] = 'PASSIVE'
os.environ['OMP_MAX_ACTIVE_LEVELS'] = '1'
# GNU OpenMP specific settings to disable shared memory
os.environ['GOMP_CPU_AFFINITY'] = '0'
os.environ['GOMP_STACKSIZE'] = '2M'
# LLVM OpenMP specific settings to disable shared memory
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
os.environ['KMP_AFFINITY'] = 'disabled'
os.environ['KMP_TOPOLOGY_METHOD'] = 'all'
# Try to disable shared memory completely
os.environ['OMP_NESTED'] = 'FALSE'
os.environ['OMP_MAX_TASK_PRIORITY'] = '0'
# Force single-threaded execution
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['NUMEXPR_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'
logger.info("OpenMP configured for single-threaded operation with shared memory disabled")

class BitNetServer:
    def __init__(self):
        self.process = None
        self.server_ready = False
        self.port = 8080
        
    def start_server(self):
        """Start the BitNet server process."""
        try:
            logger.info("Starting BitNet server...")
            logger.info(f"Model path: /app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf")
            logger.info(f"Server will listen on 127.0.0.1:{self.port}")
            
            # Start the llama-server process with Lambda-optimized parameters
            self.process = subprocess.Popen([
                "/app/bin/llama-server",
                "-m", "/app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf",
                "-c", "2048",  # ctx_size
                "-t", "1",     # single thread for Lambda
                "-n", "4096",  # n_predict
                "-ngl", "0",   # no GPU layers
                "--temp", "0.8",  # temperature
                "--host", "127.0.0.1",
                "--port", str(self.port),
                "-cb"  # Enable continuous batching
            ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
            
            # Start a thread to capture and log server output
            import threading
            def log_server_output():
                try:
                    for line in iter(self.process.stdout.readline, ''):
                        if line.strip():
                            logger.info(f"BitNet Server: {line.strip()}")
                except Exception as e:
                    logger.error(f"Error reading server output: {str(e)}")
            
            output_thread = threading.Thread(target=log_server_output, daemon=True)
            output_thread.start()
            
            logger.info("BitNet server process started, waiting for it to be ready...")
            
            # Wait for server to be ready
            self._wait_for_server()
            logger.info("BitNet server started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start BitNet server: {str(e)}")
            if self.process and self.process.poll() is None:
                # Get any error output
                try:
                    stdout, stderr = self.process.communicate(timeout=5)
                    if stdout:
                        logger.error(f"Server stdout: {stdout}")
                    if stderr:
                        logger.error(f"Server stderr: {stderr}")
                except:
                    pass
            raise
    
    def _wait_for_server(self, max_wait=300):  # 5 minutes for server startup in Lambda
        """Wait for the server to be ready to accept requests."""
        start_time = time.time()
        logger.info(f"Waiting for server to be ready (max {max_wait} seconds)...")
        
        attempt = 0
        while time.time() - start_time < max_wait:
            attempt += 1
            elapsed = int(time.time() - start_time)
            
            if attempt % 10 == 1:  # Log every 10th attempt
                logger.info(f"Health check attempt {attempt}, elapsed: {elapsed}s")
            
            try:
                response = requests.get(f"http://127.0.0.1:{self.port}/health", timeout=30)  # 30 seconds for health check
                if response.status_code == 200:
                    self.server_ready = True
                    logger.info(f"Server is ready! Took {elapsed} seconds")
                    return
                elif response.status_code == 503:
                    # Server is running but model might still be warming up
                    # Let's try a simple completion request to see if it actually works
                    logger.info(f"Server returned 503, testing completion endpoint...")
                    try:
                        test_response = requests.post(
                            f"http://127.0.0.1:{self.port}/completion",
                            json={"prompt": "test", "n_predict": 1},
                            timeout=60
                        )
                        if test_response.status_code == 200:
                            self.server_ready = True
                            logger.info(f"Server is ready via completion test! Took {elapsed} seconds")
                            return
                        else:
                            logger.info(f"Completion test returned status {test_response.status_code}")
                    except Exception as e:
                        logger.info(f"Completion test failed: {str(e)}")
                else:
                    logger.info(f"Health check returned status {response.status_code}")
            except requests.exceptions.ConnectionError:
                # Server not ready yet, this is expected
                pass
            except requests.exceptions.Timeout:
                logger.warning(f"Health check timed out after 30 seconds (attempt {attempt})")
            except Exception as e:
                logger.warning(f"Health check error: {str(e)}")
            
            time.sleep(5)  # Wait 5 seconds between attempts
        
        # Try alternative check - simple completion request
        logger.info("Health check failed, trying completion endpoint...")
        while time.time() - start_time < max_wait:
            attempt += 1
            elapsed = int(time.time() - start_time)
            
            try:
                response = requests.post(
                    f"http://127.0.0.1:{self.port}/completion",
                    json={"prompt": "test", "n_predict": 1},
                    timeout=60  # 60 seconds for test completion
                )
                if response.status_code in [200, 503]:  # 503 might mean still loading
                    if response.status_code == 200:
                        self.server_ready = True
                        logger.info(f"Server is ready via completion endpoint! Took {elapsed} seconds")
                        return
                    elif "Loading model" not in response.text:
                        self.server_ready = True
                        logger.info(f"Server is ready (completion test passed)! Took {elapsed} seconds")
                        return
                    else:
                        logger.info(f"Server still loading model... (elapsed: {elapsed}s)")
                else:
                    logger.info(f"Completion test returned status {response.status_code}")
            except requests.exceptions.ConnectionError:
                logger.info(f"Connection refused, server still starting... (elapsed: {elapsed}s)")
            except requests.exceptions.Timeout:
                logger.warning(f"Completion test timed out (elapsed: {elapsed}s)")
            except Exception as e:
                logger.warning(f"Completion test error: {str(e)}")
            
            time.sleep(10)  # Wait 10 seconds between completion attempts
        
        logger.error(f"Server failed to start within {max_wait} seconds")
        raise Exception("Server failed to start within timeout period")
    
    def stop_server(self):
        """Stop the BitNet server process."""
        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=10)
            except:
                self.process.kill()
            self.process = None
            self.server_ready = False
    
    def make_request(self, prompt, n_predict=50):
        """Make a completion request to the BitNet server."""
        if not self.server_ready:
            raise Exception("Server is not ready")
        
        try:
            response = requests.post(
                f"http://127.0.0.1:{self.port}/completion",
                json={
                    "prompt": prompt,
                    "n_predict": n_predict,
                    "temperature": 0.8,
                    "top_p": 0.95,
                    "stream": False
                },
                timeout=720  # 12 minutes timeout for inference (within 15min Lambda limit)
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"Server returned status {response.status_code}: {response.text}")
                
        except requests.exceptions.Timeout:
            raise Exception("Request timed out")
        except Exception as e:
            raise Exception(f"Request failed: {str(e)}")

# Global server instance
bitnet_server = None

def lambda_handler(event, context):
    """AWS Lambda handler function."""
    global bitnet_server
    
    try:
        # Initialize server if not already done
        if bitnet_server is None:
            bitnet_server = BitNetServer()
            bitnet_server.start_server()
        
        # Parse the event
        if isinstance(event, str):
            event = json.loads(event)
        
        # Extract prompt and parameters
        prompt = event.get('prompt', '')
        n_predict = event.get('n_predict', 50)
        
        if not prompt:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required parameter: prompt'
                })
            }
        
        logger.info(f"Processing request with prompt length: {len(prompt)}")
        
        # Make the inference request
        result = bitnet_server.make_request(prompt, n_predict)
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

# Cleanup function for Lambda container reuse
def cleanup():
    """Cleanup function called when Lambda container is being destroyed."""
    global bitnet_server
    if bitnet_server:
        bitnet_server.stop_server()

# Register cleanup function
import atexit
atexit.register(cleanup)
