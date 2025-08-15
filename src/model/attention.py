"""
Hierarchical Attention Mechanism

Attention mechanism for communication between controller and worker modules.
Enables bidirectional information flow and hierarchical reasoning.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional, Dict, Any
import math


class HierarchicalAttention(nn.Module):
    """
    Hierarchical Attention Mechanism
    
    Enables communication between controller and worker modules:
    - Controller-to-Worker attention: High-level guidance
    - Worker-to-Controller attention: Detailed feedback
    - Cross-module attention: Bidirectional information flow
    
    Args:
        controller_dim: Controller module dimension
        worker_dim: Worker module dimension
        num_heads: Number of attention heads
        dropout: Dropout rate
        use_cross_attention: Whether to use cross-module attention
    """
    
    def __init__(
        self,
        controller_dim: int = 512,
        worker_dim: int = 256,
        num_heads: int = 8,
        dropout: float = 0.1,
        use_cross_attention: bool = True,
        **kwargs
    ):
        super().__init__()
        
        self.controller_dim = controller_dim
        self.worker_dim = worker_dim
        self.num_heads = num_heads
        self.dropout = dropout
        self.use_cross_attention = use_cross_attention
        
        # Controller-to-Worker attention
        self.controller_to_worker_attn = CrossModuleAttention(
            query_dim=worker_dim,
            key_dim=controller_dim,
            value_dim=controller_dim,
            output_dim=worker_dim,
            num_heads=num_heads,
            dropout=dropout
        )
        
        # Worker-to-Controller attention
        self.worker_to_controller_attn = CrossModuleAttention(
            query_dim=controller_dim,
            key_dim=worker_dim,
            value_dim=worker_dim,
            output_dim=controller_dim,
            num_heads=num_heads,
            dropout=dropout
        )
        
        # Cross-module attention (if enabled)
        if use_cross_attention:
            self.cross_attention = CrossModuleAttention(
                query_dim=controller_dim,
                key_dim=worker_dim,
                value_dim=worker_dim,
                output_dim=controller_dim,
                num_heads=num_heads,
                dropout=dropout
            )
        
        # Gating mechanisms
        self.controller_gate = nn.Linear(controller_dim * 2, controller_dim)
        self.worker_gate = nn.Linear(worker_dim * 2, worker_dim)
        self.gate_activation = nn.Sigmoid()
        
        # Layer normalization
        self.controller_norm = nn.LayerNorm(controller_dim)
        self.worker_norm = nn.LayerNorm(worker_dim)
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(
        self,
        controller_state: torch.Tensor,
        worker_state: torch.Tensor,
        mask: Optional[torch.Tensor] = None
    ) -> Dict[str, torch.Tensor]:
        """
        Forward pass through hierarchical attention
        
        Args:
            controller_state: Controller hidden state (batch_size, controller_dim)
            worker_state: Worker hidden state (batch_size, worker_dim)
            mask: Optional attention mask
            
        Returns:
            Dictionary containing:
            - controller_output: Updated controller state
            - worker_output: Updated worker state
            - attention_weights: Attention weights
        """
        batch_size = controller_state.shape[0]
        
        # Reshape for attention (add sequence dimension)
        controller_seq = controller_state.unsqueeze(1)  # (batch, 1, controller_dim)
        worker_seq = worker_state.unsqueeze(1)  # (batch, 1, worker_dim)
        
        # Controller-to-Worker attention
        c2w_output = self.controller_to_worker_attn(
            query=worker_seq,
            key=controller_seq,
            value=controller_seq,
            mask=mask
        )
        
        # Worker-to-Controller attention
        w2c_output = self.worker_to_controller_attn(
            query=controller_seq,
            key=worker_seq,
            value=worker_seq,
            mask=mask
        )
        
        # Cross-module attention (if enabled)
        cross_output = None
        if self.use_cross_attention:
            cross_output = self.cross_attention(
                query=controller_seq,
                key=worker_seq,
                value=worker_seq,
                mask=mask
            )
        
        # Combine attention outputs with gating
        # Controller output
        controller_attended = w2c_output['output'].squeeze(1)  # (batch, controller_dim)
        controller_combined = torch.cat([controller_state, controller_attended], dim=-1)
        controller_gate = self.gate_activation(self.controller_gate(controller_combined))
        controller_output = controller_gate * controller_attended + (1 - controller_gate) * controller_state
        
        # Add cross-attention if enabled
        if cross_output is not None:
            cross_attended = cross_output['output'].squeeze(1)
            controller_output = controller_output + cross_attended
        
        # Worker output
        worker_attended = c2w_output['output'].squeeze(1)  # (batch, worker_dim)
        worker_combined = torch.cat([worker_state, worker_attended], dim=-1)
        worker_gate = self.gate_activation(self.worker_gate(worker_combined))
        worker_output = worker_gate * worker_attended + (1 - worker_gate) * worker_state
        
        # Layer normalization
        controller_output = self.controller_norm(controller_output)
        worker_output = self.worker_norm(worker_output)
        
        # Apply dropout
        controller_output = self.dropout_layer(controller_output)
        worker_output = self.dropout_layer(worker_output)
        
        # Prepare attention weights
        attention_weights = {
            'controller_to_worker': c2w_output['attention_weights'],
            'worker_to_controller': w2c_output['attention_weights']
        }
        
        if cross_output is not None:
            attention_weights['cross_attention'] = cross_output['attention_weights']
        
        return {
            'controller_output': controller_output,
            'worker_output': worker_output,
            'attention_weights': attention_weights
        }


class CrossModuleAttention(nn.Module):
    """
    Cross-module attention mechanism
    
    Enables attention between different modules with different dimensions.
    Handles dimension mismatch through linear projections.
    """
    
    def __init__(
        self,
        query_dim: int,
        key_dim: int,
        value_dim: int,
        output_dim: int,
        num_heads: int = 8,
        dropout: float = 0.1
    ):
        super().__init__()
        
        self.query_dim = query_dim
        self.key_dim = key_dim
        self.value_dim = value_dim
        self.output_dim = output_dim
        self.num_heads = num_heads
        self.dropout = dropout
        
        # Calculate head dimension (use minimum dimension)
        min_dim = min(query_dim, key_dim, value_dim)
        self.head_dim = min_dim // num_heads
        
        assert self.head_dim > 0, "Head dimension must be positive"
        
        # Linear projections
        self.query_proj = nn.Linear(query_dim, num_heads * self.head_dim)
        self.key_proj = nn.Linear(key_dim, num_heads * self.head_dim)
        self.value_proj = nn.Linear(value_dim, num_heads * self.head_dim)
        self.output_proj = nn.Linear(num_heads * self.head_dim, output_dim)
        
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
        Cross-module attention forward pass
        
        Args:
            query: Query tensor (batch_size, seq_len, query_dim)
            key: Key tensor (batch_size, seq_len, key_dim)
            value: Value tensor (batch_size, seq_len, value_dim)
            mask: Optional attention mask
            
        Returns:
            Dictionary containing output and attention weights
        """
        batch_size, query_seq_len, _ = query.shape
        _, key_seq_len, _ = key.shape
        
        # Linear projections
        Q = self.query_proj(query)
        K = self.key_proj(key)
        V = self.value_proj(value)
        
        # Reshape for multi-head attention
        Q = Q.view(batch_size, query_seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        K = K.view(batch_size, key_seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        V = V.view(batch_size, key_seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        
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
            batch_size, query_seq_len, self.num_heads * self.head_dim
        )
        
        # Output projection
        output = self.output_proj(attended)
        
        return {
            'output': output,
            'attention_weights': attention_weights
        }


class HierarchicalSelfAttention(nn.Module):
    """
    Hierarchical self-attention within each module
    
    Enables the module to attend to its own internal states
    at different hierarchical levels.
    """
    
    def __init__(
        self,
        dim: int,
        num_heads: int = 8,
        num_levels: int = 3,
        dropout: float = 0.1
    ):
        super().__init__()
        
        self.dim = dim
        self.num_heads = num_heads
        self.num_levels = num_levels
        self.dropout = dropout
        self.head_dim = dim // num_heads
        
        assert dim % num_heads == 0, "dim must be divisible by num_heads"
        
        # Multi-level attention layers
        self.level_attentions = nn.ModuleList([
            MultiHeadAttention(
                dim=dim,
                num_heads=num_heads,
                dropout=dropout
            ) for _ in range(num_levels)
        ])
        
        # Level-specific projections
        self.level_projections = nn.ModuleList([
            nn.Linear(dim, dim) for _ in range(num_levels)
        ])
        
        # Output projection
        self.output_proj = nn.Linear(dim * num_levels, dim)
        
        # Layer normalization
        self.layer_norms = nn.ModuleList([
            nn.LayerNorm(dim) for _ in range(num_levels)
        ])
        
        # Dropout
        self.dropout_layer = nn.Dropout(dropout)
        
    def forward(
        self,
        x: torch.Tensor,
        mask: Optional[torch.Tensor] = None
    ) -> Dict[str, torch.Tensor]:
        """
        Hierarchical self-attention forward pass
        
        Args:
            x: Input tensor (batch_size, seq_len, dim)
            mask: Optional attention mask
            
        Returns:
            Dictionary containing output and attention weights
        """
        batch_size, seq_len, _ = x.shape
        
        level_outputs = []
        attention_weights = []
        
        for level_idx in range(self.num_levels):
            # Level-specific projection
            x_level = self.level_projections[level_idx](x)
            
            # Layer normalization
            x_norm = self.layer_norms[level_idx](x_level)
            
            # Self-attention at this level
            attn_output = self.level_attentions[level_idx](
                x_norm, x_norm, x_norm, mask=mask
            )
            
            level_outputs.append(attn_output['output'])
            attention_weights.append(attn_output['attention_weights'])
        
        # Combine level outputs
        combined = torch.cat(level_outputs, dim=-1)
        output = self.output_proj(combined)
        
        # Apply dropout
        output = self.dropout_layer(output)
        
        return {
            'output': output,
            'attention_weights': attention_weights,
            'level_outputs': level_outputs
        }


class MultiHeadAttention(nn.Module):
    """Standard multi-head attention mechanism"""
    
    def __init__(
        self,
        dim: int,
        num_heads: int = 8,
        dropout: float = 0.1
    ):
        super().__init__()
        
        self.dim = dim
        self.num_heads = num_heads
        self.head_dim = dim // num_heads
        self.dropout = dropout
        
        assert dim % num_heads == 0, "dim must be divisible by num_heads"
        
        # Linear projections
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
        
        return {
            'output': output,
            'attention_weights': attention_weights
        }



