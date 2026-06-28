import os
import sys
import importlib.util

_DIR = os.path.dirname(os.path.abspath(__file__))


def _load(modname, fname):
    spec = importlib.util.spec_from_file_location(modname, os.path.join(_DIR, fname))
    mod = importlib.util.module_from_spec(spec)
    sys.modules[modname] = mod
    spec.loader.exec_module(mod)
    return mod


# uid38 (.pt detector) and uid94 (.onnx detector + XGBoost map classifier) as native agents
_pt_mod = _load("_route_agent_pt", "agent_pt.py")
_onnx_mod = _load("_route_agent_onnx", "agent_onnx.py")

# maps where uid38's .pt detector wins; everything else -> uid94's native agent
_PT_LABELS = ("mountain", "village")


class DroneFlightController:
    def __init__(self, **kwargs):
        self._agent_pt = _pt_mod.DroneFlightController()
        self._agent_onnx = _onnx_mod.DroneFlightController()

    def reset(self):
        for a in (self._agent_pt, self._agent_onnx):
            if hasattr(a, "reset"):
                a.reset()

    def act(self, observation):
        # run BOTH native agents every tick so each keeps full internal state warm
        a_pt = self._agent_pt.act(observation)
        a_onnx = self._agent_onnx.act(observation)
        # uid94's native agent runs the XGBoost map classifier -> read its label
        label = getattr(self._agent_onnx, "_map_prediction_label", None)
        if label is None or label in _PT_LABELS:
            return a_pt
        return a_onnx
