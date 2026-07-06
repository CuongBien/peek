import os
import sys
import subprocess

# Color formatting helpers for terminal output
def print_info(text):
    print(f"\033[94m[INFO] {text}\033[0m")

def print_success(text):
    print(f"\033[92m[SUCCESS] {text}\033[0m")

def print_error(text):
    print(f"\033[91m[ERROR] {text}\033[0m")

def create_clean_structure(project_dir):
    # Core directories matching carrot structure plus standard clean architecture
    dirs = [
        # Assets & API Mocks
        'assets/images',
        'mock_api',
        
        # Core & Common layers
        'lib/common/models',
        'lib/core/di',
        'lib/core/network',
        'lib/core/theme',
        'lib/core/utils',
        
        # Features Layer - Auth
        'lib/features/auth/data/datasources',
        'lib/features/auth/data/models',
        'lib/features/auth/data/repositories',
        'lib/features/auth/domain/entities',
        'lib/features/auth/domain/repositories',
        'lib/features/auth/domain/usecases',
        'lib/features/auth/presentation/cubit',
        'lib/features/auth/presentation/screens',
        'lib/features/auth/presentation/widgets',
        
        # Features Layer - Product
        'lib/features/product/data/datasources',
        'lib/features/product/data/models',
        'lib/features/product/data/repositories',
        'lib/features/product/domain/entities',
        'lib/features/product/domain/repositories',
        'lib/features/product/domain/usecases',
        'lib/features/product/presentation/cubit',
        'lib/features/product/presentation/screens',
        'lib/features/product/presentation/widgets',
        
        # Features Layer - Profile
        'lib/features/profile/data/datasources',
        'lib/features/profile/data/models',
        'lib/features/profile/data/repositories',
        'lib/features/profile/domain/entities',
        'lib/features/profile/domain/repositories',
        'lib/features/profile/domain/usecases',
        'lib/features/profile/presentation/cubit',
        'lib/features/profile/presentation/screens',
        'lib/features/profile/presentation/widgets',
        
        # Test folder
        'test'
    ]

    for d in dirs:
        path = os.path.join(project_dir, d)
        os.makedirs(path, exist_ok=True)
        # Create a .gitkeep file so git registers empty directories
        gitkeep_path = os.path.join(path, '.gitkeep')
        with open(gitkeep_path, 'w') as f:
            pass
        print_info(f"Created folder: {d}/")

def main():
    print("====================================================")
    print(" Flutter New Project & Clean Arch Setup Script      ")
    print("====================================================")

    project_name = ""
    
    # Check if project name was passed as argument
    if len(sys.argv) > 1:
        project_name = sys.argv[1].strip()
    
    # Prompt user if not provided
    if not project_name:
        try:
            project_name = input("Enter the new Flutter project name (e.g. my_cool_app): ").strip()
        except KeyboardInterrupt:
            print("\nOperation cancelled.")
            sys.exit(0)

    if not project_name:
        print_error("Project name cannot be empty.")
        sys.exit(1)

    # Validate project name is a valid dart package name
    if not project_name.isidentifier() or project_name.lower() != project_name:
        print_error("Flutter project name must be lowercase snake_case (e.g., my_cool_app).")
        sys.exit(1)

    print_info(f"Creating new Flutter project: '{project_name}'...")
    
    try:
        # Run flutter create command with shell=True to resolve flutter/flutter.bat on Windows PATH
        subprocess.run(["flutter", "create", project_name], check=True, shell=True)
        print_success(f"Flutter project '{project_name}' initialized successfully.")
    except FileNotFoundError:
        print_error("Flutter SDK was not found in your system PATH. Please ensure Flutter is installed.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to create Flutter project: {e}")
        sys.exit(1)

    # Get absolute path of the new project directory
    project_dir = os.path.abspath(project_name)

    print_info(f"Setting up Clean Architecture folders inside: {project_dir}")
    create_clean_structure(project_dir)

    print("====================================================")
    print_success(f"Successfully created '{project_name}' with Clean Architecture structure!")
    print_info(f"Change directory with: cd {project_name}")
    print("====================================================")

if __name__ == '__main__':
    main()
