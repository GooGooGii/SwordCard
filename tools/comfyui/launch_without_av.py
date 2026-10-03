"""以「替身 av 模組」啟動 ComfyUI（API 模式），給 tools/comfyui/hunyuan3d_mv.py 用。

原因：這台電腦的 Windows 應用程式控制原則封鎖了 PyAV 的 DLL（av._core），
ComfyUI 啟動時就 import av 而直接失敗。Hunyuan3D 不需要影片功能，所以在載入前
放一個替身：被封鎖的 DLL 完全不會被載入，也不修改 ComfyUI 安裝或系統設定；
任何真正用到影片的節點會在呼叫時報錯。

用法：
  <ComfyUI>/venv/Scripts/python.exe tools/comfyui/launch_without_av.py <ComfyUI 目錄> [main.py 參數...]
  例：... launch_without_av.py C:/AI/StabilityMatrix/Data/Packages/ComfyUI --listen 127.0.0.1 --port 8188 --disable-auto-launch
"""
import importlib.abc
import importlib.machinery
import os
import runpy
import sys
import types


class _Anything:
    """寬鬆替身：任何屬性、呼叫、迭代都回傳替身或空值。"""

    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return _Anything()

    def __call__(self, *args, **kwargs):
        return _Anything()

    def __iter__(self):
        return iter(())

    def __bool__(self):
        return False


class _StubMeta(type):
    def __getattr__(cls, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return _StubMeta(name, (), {})

    def __call__(cls, *args, **kwargs):
        return _Anything()


class _StubModule(types.ModuleType):
    __version__ = "0.0.0-stub"

    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        if name == "open":
            def _blocked(*args, **kwargs):
                raise RuntimeError("PyAV 被本機應用程式控制原則封鎖，影片功能不可用")
            return _blocked
        return _StubMeta(name, (), {})


class _AvFinder(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    def find_spec(self, fullname, path, target=None):
        if fullname == "av" or fullname.startswith("av."):
            return importlib.machinery.ModuleSpec(fullname, self, is_package=True)
        return None

    def create_module(self, spec):
        module = _StubModule(spec.name)
        module.__path__ = []
        return module

    def exec_module(self, module):
        pass


_VIDEO_TYPES = "comfy_api.latest._input_impl.video_types"


def _patch_video_types(module) -> None:
    """LoadImage 會先用 PyAV（VideoFromFile）讀圖、讀不到幀才退回 PIL：讓它直接拿到空結果。"""
    import torch

    class _NoFrames:
        images = torch.zeros((0, 1, 1, 3))
        alpha = None
        audio = None
        frame_rate = None

    module.VideoFromFile.get_components = lambda self, *args, **kwargs: _NoFrames()


class _PatchAfterImport(importlib.abc.MetaPathFinder):
    """模組載入後立刻打補丁（ComfyUI 之後 import 拿到的就是補過的）。"""

    def find_spec(self, fullname, path, target=None):
        if fullname != _VIDEO_TYPES:
            return None
        for finder in sys.meta_path:
            if finder is self or not hasattr(finder, "find_spec"):
                continue
            spec = finder.find_spec(fullname, path, target)
            if spec is not None and spec.loader is not None:
                original = spec.loader.exec_module

                def exec_module(module, _original=original):
                    _original(module)
                    _patch_video_types(module)

                spec.loader.exec_module = exec_module
                return spec
        return None


def main() -> None:
    comfy_dir = os.path.abspath(sys.argv[1])
    sys.meta_path.insert(0, _AvFinder())
    sys.meta_path.insert(0, _PatchAfterImport())
    sys.argv = [os.path.join(comfy_dir, "main.py")] + sys.argv[2:]
    sys.path.insert(0, comfy_dir)
    os.chdir(comfy_dir)
    runpy.run_path(os.path.join(comfy_dir, "main.py"), run_name="__main__")


if __name__ == "__main__":
    main()
