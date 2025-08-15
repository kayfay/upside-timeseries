"""
Hierarchical Reasoning Model (HRM)

Main implementation of the brain-inspired hierarchical reasoning architecture.
Based on the research paper: "Hierarchical Reasoning Model" by Guan Wang et al.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional, Tuple, Dict, Any
import math

from .controller import Controller
from .worker import Worker
from .attention import HierarchicalAttention


class HRM(nn.Module):
    """
    Hierarchical Reasoning Model (HRM)
    
    A brain-inspired recurrent architecture with two interdependent modules:
    - Controller: High-level, abstract planning (cortex-like)
    - Worker: Low-level, rapid computations (brainstem-like)
    
    Args:
        input_dim: Input feature dimension
        controller_dim: Controller module hidden dimension
        worker_dim: Worker module hidden dimension
        num_layers: Number of hierarchical layers
        num_cycles: Number of reasoning cycles per forward pass
        dropout: Dropout rate
        use_attention: Whether to use hierarchical attention
        use_positional_encoding: Whether to use positional encoding
    """
    
    def __init__(
        self,
        input_dim: int = 128,
        controller_dim: int = 512,
        worker_dim: int = 256,
        num_layers: int = 4,
        num_cycles: int = 6,
        dropout: float = 0.1,
        use_attention: bool = True,
        use_positional_encoding: bool = True,
        **kwargs
    ):
        super().__init__()
        
        self.input_dim = input_dim
        self.controller_dim = controller_dim
        self.worker_dim = worker_dim
        self.num_layers = num_layers
        self.num_cycles = num_cycles
        self.dropout = dropout
        self.use_attention = use_attention
        self.use_positional_encoding = use_positional_encoding
        
        # Input projection
        self.input_projection = nn.Linear(input_dim, controller_dim)
        
        # Controller module (cortex-like)
        self.controller = Controller(
            dim=controller_dim,
            num_layers=num_layers,
            dropout=dropout
        )
        
        # Worker module (brainstem-like)
        self.worker = Worker(
            dim=worker_dim,
            num_layers=num_layers,
            dropout=dropout
        )
        
        # Hierarchical attention mechanism
        if use_attention:
            self.attention = HierarchicalAttention(
                controller_dim=controller_dim,
                worker_dim=worker_dim,
                num_heads=8,
                dropout=dropout
            )
        
        # Communication layers between controller and worker
        self.controller_to_worker = nn.Linear(controller_dim, worker_dim)
        self.worker_to_controller = nn.Linear(worker_dim, controller_dim)
        
        # Output projection
        self.output_projection = nn.Linear(controller_dim, input_dim)
        
        # Layer normalization
        self.layer_norm = nn.LayerNorm(controller_dim)
        
        # Positional encoding
        if use_positional_encoding:
            self.pos_encoding = PositionalEncoding(controller_dim, max_len=1000)
        
        # Initialize weights
        self._init_weights()
    
    def _init_weights(self):
        """Initialize model weights"""
        for module in self.modules():
            if isinstance(module, nn.Linear):
                nn.init.xavier_uniform_(module.weight)
                if module.bias is not None:
                    nn.init.zeros_(module.bias)
            elif isinstance(module, nn.LayerNorm):
                nn.init.ones_(module.weight)
                nn.init.zeros_(module.bias)
    
    def forward(
        self, 
        x: torch.Tensor,
        mask: Optional[torch.Tensor] = None,
        return_attention: bool = False
    ) -> Dict[str, torch.Tensor]:
        """
        Forward pass through the HRM
        
        Args:
            x: Input tensor of shape (batch_size, seq_len, input_dim)
            mask: Optional attention mask
            return_attention: Whether to return attention weights
            
        Returns:
            Dictionary containing:
            - output: Final output tensor
            - controller_states: Controller hidden states
            - worker_states: Worker hidden states
            - attention_weights: Attention weights (if return_attention=True)
        """
        batch_size, seq_len, _ = x.shape
        
        # Input projection
        x = self.input_projection(x)
        
        # Add positional encoding
        if self.use_positional_encoding:
            x = self.pos_encoding(x)
        
        # Initialize hidden states
        controller_state = torch.zeros(
            batch_size, self.controller_dim, device=x.device
        )
        worker_state = torch.zeros(
            batch_size, self.worker_dim, device=x.device
        )
        
        # Store states for each cycle
        controller_states = []
        worker_states = []
        attention_weights = []
        
        # Multi-cycle reasoning
        for cycle in range(self.num_cycles):
            # Controller processing (high-level planning)
            controller_output = self.controller(
                x, 
                controller_state,
                mask=mask
            )
            controller_state = controller_output['hidden_state']
            controller_states.append(controller_state)
            
            # Worker processing (low-level computation)
            worker_input = self.controller_to_worker(controller_state)
            worker_output = self.worker(
                worker_input,
                worker_state
            )
            worker_state = worker_output['hidden_state']
            worker_states.append(worker_state)
            
            # Hierarchical attention (if enabled)
            if self.use_attention:
                attended_output = self.attention(
                    controller_state,
                    worker_state,
                    mask=mask
                )
                controller_state = attended_output['controller_output']
                worker_state = attended_output['worker_output']
                
                if return_attention:
                    attention_weights.append(attended_output['attention_weights'])
            
            # Feedback from worker to controller
            controller_feedback = self.worker_to_controller(worker_state)
            controller_state = controller_state + controller_feedback
            
            # Layer normalization
            controller_state = self.layer_norm(controller_state)
        
        # Output projection
        output = self.output_projection(controller_state)
        
        # Prepare return dictionary
        result = {
            'output': output,
            'controller_states': torch.stack(controller_states, dim=1),
            'worker_states': torch.stack(worker_states, dim=1),
            'final_controller_state': controller_state,
            'final_worker_state': worker_state
        }
        
        if return_attention and self.use_attention:
            result['attention_weights'] = torch.stack(attention_weights, dim=1)
        
        return result
    
    def get_num_parameters(self) -> int:
        """Get total number of parameters"""
        return sum(p.numel() for p in self.parameters())
    
    def get_trainable_parameters(self) -> int:
        """Get number of trainable parameters"""
        return sum(p.numel() for p in self.parameters() if p.requires_grad)


class PositionalEncoding(nn.Module):
    """Positional encoding for sequence modeling"""
    
    def __init__(self, d_model: int, max_len: int = 5000):
        super().__init__()
        
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * 
                           (-math.log(10000.0) / d_model))
        
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0).transpose(0, 1)
        
        self.register_buffer('pe', pe)
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Add positional encoding to input"""
        return x + self.pe[:x.size(0), :]


def create_hrm_model(
    input_dim: int = 128,
    controller_dim: int = 512,
    worker_dim: int = 256,
    num_layers: int = 4,
    num_cycles: int = 6,
    **kwargs
) -> HRM:
    """
    Factory function to create HRM model
    
    Args:
        input_dim: Input feature dimension
        controller_dim: Controller module dimension
        worker_dim: Worker module dimension
        num_layers: Number of layers
        num_cycles: Number of reasoning cycles
        
    Returns:
        Configured HRM model
    """
    return HRM(
        input_dim=input_dim,
        controller_dim=controller_dim,
        worker_dim=worker_dim,
        num_layers=num_layers,
        num_cycles=num_cycles,
        **kwargs
    )



