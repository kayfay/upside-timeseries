"""
Hierarchical Reasoning Model (HRM)

A brain-inspired AI architecture that achieves exceptional reasoning capabilities
with minimal data and computational resources.

Author: Your Name
License: MIT
"""

__version__ = "0.1.0"
__author__ = "Your Name"
__email__ = "your.email@example.com"

from .model.hrm import HRM
from .training.trainer import HRMTrainer

__all__ = [
    "HRM",
    "HRMTrainer",
]



