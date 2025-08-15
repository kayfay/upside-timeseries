"""
Controller Module (Cortex-like)

High-level, abstract reasoning module inspired by the human cortex.
Responsible for strategic planning, goal setting, and abstract thinking.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional, Dict, Any
import math


class Controller(nn.Module):
    """
    Controller Module - High-level reasoning (Cortex-like)
    
    The controller module is responsible for:
    - Abstract planning and goal setting
    - Strategic decision making
    - Long-term reasoning
    - Slow, deliberate processing
    
    Args:
        dim: Hidden dimension
        num_layers: Number of controller layers
        num_heads: Number of attention heads
        dropout: Dropout rate
        use_gated_attention: Whether to use gated attention mechanism
    """
    
    def __init__(
        self,
        dim: int = 512,
        num_layers: int = 4,
        num_heads: int = 8,
        dropout: float = 0.1,
        use_gated_attention: bool = True,
        **kwargs
    ):
        super().__init__()
        
        self.dim = dim
        self.num_layers = num_layers
        self.num_heads = num_heads
        self.dropout = dropout
        self.use_gated_attention = use_gated_attention
        
        # Multi-head self-attention
        self.self_attention = nn.ModuleList([
            MultiHeadAttention(
                dim=dim,
                num_heads=num_heads,
                dropout=dropout,
                use_gated=use_gated_attention
            ) for _ in range(num_layers)
        ])
        
        # Feed-forward networks
        self.feed_forward = nn.ModuleList([
            FeedForward(dim=dim, dropout=dropout)
            for _ in range(num_layers)
        ])
        
        # Layer normalization
        self.layer_norms = nn.ModuleList([
            nn.LayerNorm(dim) for _ in range(num_layers * 2)
        ])
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
        # Planning network (for abstract reasoning)
        self.planning_network = PlanningNetwork(dim=dim, dropout=dropout)
        
        # Goal representation
        self.goal_encoder = GoalEncoder(dim=dim)
        
    def forward(
        self,
        x: torch.Tensor,
        hidden_state: torch.Tensor,
        mask: Optional[torch.Tensor] = None
    ) -> Dict[str, torch.Tensor]:
        """
        Forward pass through the controller
        
        Args:
            x: Input sequence (batch_size, seq_len, dim)
            hidden_state: Previous hidden state (batch_size, dim)
            mask: Optional attention mask
            
        Returns:
            Dictionary containing:
            - hidden_state: Updated hidden state
            - attention_weights: Attention weights
            - planning_output: Planning network output
        """
        batch_size, seq_len, _ = x.shape
        
        # Encode current goal/context
        goal_encoding = self.goal_encoder(hidden_state)
        
        # Add goal encoding to input
        x = x + goal_encoding.unsqueeze(1).expand(-1, seq_len, -1)
        
        # Process through controller layers
        attention_weights = []
        current_hidden = hidden_state
        
        for layer_idx in range(self.num_layers):
            # Self-attention
            attn_norm_idx = layer_idx * 2
            ff_norm_idx = layer_idx * 2 + 1
            
            # Layer norm before attention
            x_norm = self.layer_norms[attn_norm_idx](x)
            
            # Self-attention with residual connection
            attn_output = self.self_attention[layer_idx](
                x_norm, x_norm, x_norm, mask=mask
            )
            x = x + self.dropout_layer(attn_output['output'])
            attention_weights.append(attn_output['attention_weights'])
            
            # Layer norm before feed-forward
            x_norm = self.layer_norms[ff_norm_idx](x)
            
            # Feed-forward with residual connection
            ff_output = self.feed_forward[layer_idx](x_norm)
            x = x + self.dropout_layer(ff_output)
            
            # Update hidden state with global information
            global_info = x.mean(dim=1)  # Global pooling
            current_hidden = current_hidden + global_info
        
        # Planning network for abstract reasoning
        planning_output = self.planning_network(current_hidden)
        
        # Final hidden state
        final_hidden = current_hidden + planning_output
        
        return {
            'hidden_state': final_hidden,
            'attention_weights': attention_weights,
            'planning_output': planning_output,
            'goal_encoding': goal_encoding
        }


class MultiHeadAttention(nn.Module):
    """Multi-head attention with optional gating mechanism"""
    
    def __init__(
        self,
        dim: int,
        num_heads: int = 8,
        dropout: float = 0.1,
        use_gated: bool = True
    ):
        super().__init__()
        
        self.dim = dim
        self.num_heads = num_heads
        self.head_dim = dim // num_heads
        self.dropout = dropout
        self.use_gated = use_gated
        
        assert dim % num_heads == 0, "dim must be divisible by num_heads"
        
        # Linear projections
        self.query_proj = nn.Linear(dim, dim)
        self.key_proj = nn.Linear(dim, dim)
        self.value_proj = nn.Linear(dim, dim)
        self.output_proj = nn.Linear(dim, dim)
        
        # Gating mechanism
        if use_gated:
            self.gate = nn.Linear(dim, dim)
            self.gate_activation = nn.Sigmoid()
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(
        self,
        query: torch.Tensor,
        key: torch.Tensor,
        value: torch.Tensor,
        mask: Optional[torch.Tensor] = None
    ) -> Dict[str, torch.Tensor]:
        """
        Multi-head attention forward pass
        
        Args:
            query: Query tensor
            key: Key tensor
            value: Value tensor
            mask: Optional attention mask
            
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
        
        # Apply mask if provided
        if mask is not None:
            mask = mask.unsqueeze(1).unsqueeze(1)  # Add head dimension
            scores = scores.masked_fill(mask == 0, -1e9)
        
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
        
        # Gating mechanism
        if self.use_gated:
            gate = self.gate_activation(self.gate(query))
            output = gate * output + (1 - gate) * query
        
        return {
            'output': output,
            'attention_weights': attention_weights
        }


class FeedForward(nn.Module):
    """Feed-forward network with gated linear units"""
    
    def __init__(self, dim: int, dropout: float = 0.1):
        super().__init__()
        
        self.dim = dim
        self.dropout = dropout
        
        # Gated linear units
        self.gate_proj = nn.Linear(dim, dim * 2)
        self.up_proj = nn.Linear(dim, dim * 2)
        self.down_proj = nn.Linear(dim * 2, dim)
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through feed-forward network"""
        # Gated linear units
        gate = self.gate_proj(x)
        up = self.up_proj(x)
        
        # Apply gating
        gate = F.sigmoid(gate)
        up = F.gelu(up)
        
        # Combine
        combined = gate * up
        combined = self.dropout_layer(combined)
        
        # Down projection
        output = self.down_proj(combined)
        
        return output


class PlanningNetwork(nn.Module):
    """Planning network for abstract reasoning"""
    
    def __init__(self, dim: int, dropout: float = 0.1):
        super().__init__()
        
        self.dim = dim
        self.dropout = dropout
        
        # Planning layers
        self.planning_layers = nn.Sequential(
            nn.Linear(dim, dim * 2),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(dim * 2, dim),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(dim, dim)
        )
        
        # Layer normalization
        self.layer_norm = nn.LayerNorm(dim)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through planning network"""
        # Layer normalization
        x_norm = self.layer_norm(x)
        
        # Planning computation
        planning_output = self.planning_layers(x_norm)
        
        return planning_output


class GoalEncoder(nn.Module):
    """Goal encoding network"""
    
    def __init__(self, dim: int):
        super().__init__()
        
        self.dim = dim
        
        # Goal encoding layers
        self.goal_encoder = nn.Sequential(
            nn.Linear(dim, dim),
            nn.GELU(),
            nn.Linear(dim, dim)
        )
        
    def forward(self, hidden_state: torch.Tensor) -> torch.Tensor:
        """Encode current goal/context from hidden state"""
        return self.goal_encoder(hidden_state)



