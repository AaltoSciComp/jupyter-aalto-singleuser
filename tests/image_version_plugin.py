from pathlib import Path

import pytest
from packaging.version import InvalidVersion, Version


def _image_version() -> Version | None:
    release_file = Path("/etc/cs-jupyter-release")
    if not release_file.exists():
        return None

    for line in release_file.read_text().splitlines():
        if line.startswith("IMAGE_VERSION="):
            try:
                return Version(line.removeprefix("IMAGE_VERSION=").rpartition(":")[2])
            except InvalidVersion:
                return None

    return None


def pytest_runtest_setup(item):
    marker = item.get_closest_marker("requires_image_version")
    if marker is None:
        return

    if len(marker.args) != 1 or marker.kwargs:
        raise pytest.UsageError("requires_image_version requires exactly one version argument")

    try:
        required_version = Version(marker.args[0])
    except InvalidVersion as exc:
        raise pytest.UsageError(
            f"requires_image_version has invalid version {marker.args[0]!r}"
        ) from exc

    image_version = _image_version()
    print(f"Image version: {image_version}, required: {required_version}")
    if image_version is None or image_version < required_version:
        actual_version = str(image_version) if image_version is not None else "unknown"
        pytest.skip(
            f"requires image version >= {required_version}; found {actual_version}"
        )
