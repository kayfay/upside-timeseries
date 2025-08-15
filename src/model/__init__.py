"""
HRM Model Components

This package contains the core HRM architecture including:
- Main HRM model
- Controller module (cortex-like)
- Worker module (brainstem-like)
- Attention mechanisms
- Hierarchical communication layers
"""

from .hrm import HRM
from .controller import Controller
from .worker import Worker
from .attention import HierarchicalAttention

__all__ = [
    "HRM",
    "Controller", 
    "Worker",
    "HierarchicalAttention",
]



