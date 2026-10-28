import tensorflow as tf
  
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    print(f"GPUs are available: {gpus}")
else:
    print("No GPU is available.")

with tf.device('/GPU:0'):  # Ensures the operation runs on GPU
    a = tf.random.normal([1000, 1000])
    b = tf.random.normal([1000, 1000])
    result = tf.matmul(a, b)

print("Matrix multiplication result shape:", result.shape)
