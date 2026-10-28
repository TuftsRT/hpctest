import torch
import torch.nn as nn
import torch.optim as optim

# Check if GPU is available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Define a simple neural network
class SimpleNN(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(SimpleNN, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# Parameters
input_size = 10
hidden_size = 20
output_size = 5
batch_size = 32
num_epochs = 10
learning_rate = 0.01

# Generate random input and output data, and move them to the GPU
torch.manual_seed(0)  # For reproducibility
X = torch.randn(batch_size, input_size).to(device)
y = torch.randint(0, output_size, (batch_size,)).to(device)

# Create the model, loss function, and optimizer, and move them to the GPU
model = SimpleNN(input_size, hidden_size, output_size).to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=learning_rate)

# Training loop
print("Training on GPU..." if torch.cuda.is_available() else "GPU not available, running on CPU.")
for epoch in range(num_epochs):
    # Forward pass
    outputs = model(X)
    loss = criterion(outputs, y)

    # Backward pass
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    print(f"Epoch [{epoch+1}/{num_epochs}], Loss: {loss.item():.4f}")
