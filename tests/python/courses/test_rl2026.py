def test_rl2026():
    import importlib
    import importlib.metadata

    from packaging import version
    from packaging.specifiers import SpecifierSet

    # rl2026, RT#33032
    dependencies = [
        # (module_name for import, distribution_name from pypi, version specifier)
        ("gymnasium", "gymnasium", ">=1.2,<2"),
        ("torch", "torch", ">=2.5"),
        ("numpy", "numpy", ">=2.1,<3"),

        ("matplotlib", "matplotlib", ">=3.9"),
        ("pandas", "pandas", ">=2.2,<3"),
        ("seaborn", "seaborn", ">=0.13"),
        ("scipy", "scipy", ">=1.14"),
        ("sklearn", "scikit-learn", ">=1.5"),
        ("yaml", "pyyaml", ">=6.0"),

        ("moviepy", "moviepy", ">=2.1,<3"),
        ("imageio", "imageio", ">=2.34,<3"),
        ("imageio_ffmpeg", "imageio-ffmpeg", ">=0.5"),
        ("PIL", "pillow", ">=10"),
        ("pygame", "pygame-ce", ">=2.1.3,<3"),

        ("jupyterlab", "jupyterlab", ">=4.2"),
        ("ipykernel", "ipykernel", ">=6"),
        ("IPython", "ipython", ">=8"),
        ("ipywidgets", "ipywidgets", ">=8.1,<9"),
    ]

    issues = []
    for module_name, distribution_name, specifier in dependencies:
        try:
            module = importlib.import_module(module_name)
        except ModuleNotFoundError:
            issues.append(f"Missing dependency {distribution_name!r} (module {module_name!r})")
            continue

        installed_version = getattr(module, "__version__", None)
        if installed_version is None:
            try:
                installed_version = importlib.metadata.version(distribution_name)
            except importlib.metadata.PackageNotFoundError:
                issues.append(f"Dependency {distribution_name!r} is not installed")
                continue

        try:
            parsed_version = version.parse(installed_version)
            if parsed_version not in SpecifierSet(specifier):
                issues.append(
                    f"Dependency {distribution_name!r} has version {installed_version!r}, "
                    f"expected {specifier}"
                )
        except Exception as exc:  # pragma: no cover - safeguards against malformed metadata
            issues.append(
                f"Dependency {distribution_name!r} has invalid version {installed_version!r}: {exc}"
            )

    if issues:
        raise AssertionError("\n".join(issues))
