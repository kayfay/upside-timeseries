"""
Worker Module (Brainstem-like)

Low-level, rapid computational module inspired by the human brainstem.
Responsible for fast, automatic responses and detailed computations.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional, Dict, Any
import math


class Worker(nn.Module):
    """
    Worker Module - Low-level computation (Brainstem-like)
    
    The worker module is responsible for:
    - Fast, automatic computations
    - Detailed pattern recognition
    - Rapid responses
    - Efficient processing
    
    Args:
        dim: Hidden dimension
        num_layers: Number of worker layers
        dropout: Dropout rate
        use_conv: Whether to use convolutional layers
        use_gru: Whether to use GRU cells
    """
    
    def __init__(
        self,
        dim: int = 256,
        num_layers: int = 4,
        dropout: float = 0.1,
        use_conv: bool = True,
        use_gru: bool = True,
        **kwargs
    ):
        super().__init__()
        
        self.dim = dim
        self.num_layers = num_layers
        self.dropout = dropout
        self.use_conv = use_conv
        self.use_gru = use_gru
        
        # Input projection
        self.input_projection = nn.Linear(dim, dim)
        
        # Worker layers
        self.worker_layers = nn.ModuleList([
            WorkerLayer(
                dim=dim,
                dropout=dropout,
                use_conv=use_conv,
                use_gru=use_gru
            ) for _ in range(num_layers)
        ])
        
        # Layer normalization
        self.layer_norms = nn.ModuleList([
            nn.LayerNorm(dim) for _ in range(num_layers)
        ])
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
        # Pattern recognition network
        self.pattern_network = PatternRecognitionNetwork(dim=dim, dropout=dropout)
        
        # Fast response network
        self.response_network = FastResponseNetwork(dim=dim, dropout=dropout)
        
    def forward(
        self,
        x: torch.Tensor,
        hidden_state: torch.Tensor
    ) -> Dict[str, torch.Tensor]:
        """
        Forward pass through the worker
        
        Args:
            x: Input tensor (batch_size, dim)
            hidden_state: Previous hidden state (batch_size, dim)
            
        Returns:
            Dictionary containing:
            - hidden_state: Updated hidden state
            - pattern_output: Pattern recognition output
            - response_output: Fast response output
        """
        batch_size = x.shape[0]
        
        # Input projection
        x = self.input_projection(x)
        
        # Process through worker layers
        current_hidden = hidden_state
        layer_outputs = []
        
        for layer_idx in range(self.num_layers):
            # Layer normalization
            x_norm = self.layer_norms[layer_idx](x)
            
            # Worker layer processing
            worker_output = self.worker_layers[layer_idx](
                x_norm, current_hidden
            )
            
            # Update hidden state
            current_hidden = worker_output['hidden_state']
            layer_outputs.append(worker_output['output'])
            
            # Residual connection
            x = x + self.dropout_layer(worker_output['output'])
        
        # Pattern recognition
        pattern_output = self.pattern_network(current_hidden)
        
        # Fast response generation
        response_output = self.response_network(current_hidden)
        
        # Final hidden state
        final_hidden = current_hidden + pattern_output + response_output
        
        return {
            'hidden_state': final_hidden,
            'pattern_output': pattern_output,
            'response_output': response_output,
            'layer_outputs': layer_outputs
        }


class WorkerLayer(nn.Module):
    """Individual worker layer with multiple computation paths"""
    
    def __init__(
        self,
        dim: int,
        dropout: float = 0.1,
        use_conv: bool = True,
        use_gru: bool = True
    ):
        super().__init__()
        
        self.dim = dim
        self.dropout = dropout
        self.use_conv = use_conv
        self.use_gru = use_gru
        
        # Linear transformation
        self.linear_transform = nn.Linear(dim, dim)
        
        # Convolutional processing (for spatial patterns)
        if use_conv:
            self.conv_layer = nn.Conv1d(
                in_channels=dim,
                out_channels=dim,
                kernel_size=3,
                padding=1
            )
        
        # GRU cell (for temporal patterns)
        if use_gru:
            self.gru_cell = nn.GRUCell(dim, dim)
        
        # Gated mechanism
        self.gate = nn.Linear(dim * 2, dim)
        self.gate_activation = nn.Sigmoid()
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(
        self,
        x: torch.Tensor,
        hidden_state: torch.Tensor
    ) -> Dict[str, torch.Tensor]:
        """
        Forward pass through worker layer
        
        Args:
            x: Input tensor (batch_size, dim)
            hidden_state: Previous hidden state (batch_size, dim)
            
        Returns:
            Dictionary containing output and updated hidden state
        """
        batch_size = x.shape[0]
        
        # Linear transformation
        linear_output = self.linear_transform(x)
        
        # Convolutional processing
        conv_output = x
        if self.use_conv:
            # Reshape for conv1d: (batch, channels, seq_len)
            x_conv = x.unsqueeze(-1).transpose(1, 2)  # (batch, dim, 1)
            conv_output = self.conv_layer(x_conv).squeeze(-1)  # (batch, dim)
        
        # GRU processing
        gru_output = x
        if self.use_gru:
            gru_output = self.gru_cell(x, hidden_state)
        
        # Combine outputs with gating
        combined = torch.cat([conv_output, gru_output], dim=-1)
        gate = self.gate_activation(self.gate(combined))
        
        # Gated combination
        output = gate * conv_output + (1 - gate) * gru_output
        
        # Add linear transformation
        output = output + linear_output
        
        # Apply dropout
        output = self.dropout_layer(output)
        
        # Update hidden state
        new_hidden = hidden_state + output
        
        return {
            'output': output,
            'hidden_state': new_hidden
        }


class PatternRecognitionNetwork(nn.Module):
    """Pattern recognition network for detecting regularities"""
    
    def __init__(self, dim: int, dropout: float = 0.1):
        super().__init__()
        
        self.dim = dim
        self.dropout = dropout
        
        # Pattern recognition layers
        self.pattern_layers = nn.Sequential(
            nn.Linear(dim, dim * 2),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(dim * 2, dim),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(dim, dim)
        )
        
        # Layer normalization
        self.layer_norm = nn.LayerNorm(dim)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through pattern recognition network"""
        # Layer normalization
        x_norm = self.layer_norm(x)
        
        # Pattern recognition
        pattern_output = self.pattern_layers(x_norm)
        
        return pattern_output


class FastResponseNetwork(nn.Module):
    """Fast response network for rapid computations"""
    
    def __init__(self, dim: int, dropout: float = 0.1):
        super().__init__()
        
        self.dim = dim
        self.dropout = dropout
        
        # Fast response layers (shallow network for speed)
        self.response_layers = nn.Sequential(
            nn.Linear(dim, dim),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(dim, dim)
        )
        
        # Layer normalization
        self.layer_norm = nn.LayerNorm(dim)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through fast response network"""
        # Layer normalization
        x_norm = self.layer_norm(x)
        
        # Fast response computation
        response_output = self.response_layers(x_norm)
        
        return response_output


class EfficientAttention(nn.Module):
    """Efficient attention mechanism for worker module"""
    
    def __init__(self, dim: int, num_heads: int = 4, dropout: float = 0.1):
        super().__init__()
        
        self.dim = dim
        self.num_heads = num_heads
        self.head_dim = dim // num_heads
        self.dropout = dropout
        
        assert dim % num_heads == 0, "dim must be divisible by num_heads"
        
        # Efficient attention projections
        self.query_proj = nn.Linear(dim, dim)
        self.key_proj = nn.Linear(dim, dim)
        self.value_proj = nn.Linear(dim, dim)
        self.output_proj = nn.Linear(dim, dim)
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(
        self,
        query: torch.Tensor,
        key: torch.Tensor,
        value: torch.Tensor
    ) -> Dict[str, torch.Tensor]:
        """
        Efficient attention forward pass
        
        Args:
            query: Query tensor
            key: Key tensor
            value: Value tensor
            
        Returns:
            Dictionary containing output and attention weights
        """
        batch_size, seq_len, _ = query.shape
        
        # Linear projections
        Q = self.query_proj(query)
        K = self.key_proj(key)
        V = self.value_proj(value)
        
        # Reshape for multi-head attention
        Q = Q.view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        K = K.view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        V = V.view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        
        # Compute attention scores
        scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(self.head_dim)
        
        # Apply softmax
        attention_weights = F.softmax(scores, dim=-1)
        attention_weights = self.dropout_layer(attention_weights)
        
        # Apply attention to values
        attended = torch.matmul(attention_weights, V)
        
        # Reshape back
        attended = attended.transpose(1, 2).contiguous().view(
            batch_size, seq_len, self.dim
        )
        
        # Output projection
        output = self.output_proj(attended)
        
        return {
            'output': output,
            'attention_weights': attention_weights
        }



