#!/bin/bash
#
# Advanced scan-build script for comprehensive C code analysis
# Created: 2025-03-20
# Author: GitHub Copilot for movbou
#

# Output formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Default settings
PROJECT_NAME=$(basename $(pwd))
RESULTS_DIR="./scan-results-${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S)"
BUILD_CMD="make"
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
CLEAN_FIRST=true
OPEN_RESULTS=false
VERBOSE=false
EXIT_ON_ERROR=true

# Checkers - Comprehensive set covering core, memory, logic, and bug detection
CHECKERS=(
    # Core checkers
    "core.NullDereference"
    "core.DivideZero"
    "core.uninitialized.Branch"
    "core.uninitialized.CapturedBlockVariable"
    "core.uninitialized.UndefReturn"
    "core.UndefinedBinaryOperatorResult"
    "core.CallAndMessage"
    "core.StackAddressEscape"
    
    # Memory management checkers
    "unix.Malloc"
    "cplusplus.NewDelete"
    "unix.MallocSizeof"
    "alpha.unix.MallocSizeof"
    "cplusplus.NewDeleteLeaks"
    "alpha.cplusplus.NewDeleteLeaks"
    "unix.cstring.BadSizeArg"
    "unix.cstring.NullArg"
    "alpha.unix.PthreadLock"
    
    # Logic checkers
    "deadcode.DeadStores"
    "alpha.deadcode.UnreachableCode"
    "alpha.core.CastToStruct"
    "alpha.core.CastSize"
    "alpha.core.IdenticalExpr"
    "alpha.core.PointerArithm"
    "alpha.core.PointerSub"
    "alpha.core.SizeofPtr"
    
    # Security checkers
    "security.insecureAPI.strcpy"
    "security.insecureAPI.rand"
    "security.insecureAPI.UncheckedReturn"
    "security.FloatLoopCounter"
    "alpha.security.ArrayBoundV2"
    "security.ArrayBound"
    "alpha.unix.cstring.BufferOverlap"
    "alpha.unix.cstring.OutOfBounds"
    
    # Buffer handling
    "alpha.core.FixedAddr"
    "alpha.unix.Stream"
    "alpha.core.BoolAssignment"
)

# Function to display usage information
show_usage() {
    cat << EOF
${BOLD}Advanced scan-build wrapper script${RESET}

Usage: $(basename $0) [OPTIONS]

${BOLD}Options:${RESET}
  -h, --help              Show this help message
  -b, --build CMD         Specify build command (default: "make")
  -o, --output DIR        Specify output directory (default: timestamped dir)
  -j, --jobs N            Specify number of parallel jobs (default: auto)
  -c, --no-clean          Skip the clean step before building
  -v, --verbose           Enable verbose output
  -C, --checker-list      Display all enabled checkers and exit
  -k, --keep-going        Continue even if errors are found
  -V, --view              Open results in browser when done

${BOLD}Examples:${RESET}
  $(basename $0)                      # Run with default settings
  $(basename $0) -b "cmake --build ." # Use CMake for building
  $(basename $0) -j 8 -v              # Use 8 jobs and verbose output

${BOLD}Environment:${RESET}
  SCAN_BUILD_EXTRA_ARGS   Additional arguments to pass to scan-build
EOF
    exit 0
}

# Function to display checkers
show_checkers() {
    echo -e "${BOLD}Enabled checkers:${RESET}"
    for checker in "${CHECKERS[@]}"; do
        echo "  - $checker"
    done
    echo -e "\n${BOLD}Total:${RESET} ${#CHECKERS[@]} checkers enabled"
    exit 0
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        -b|--build)
            BUILD_CMD="$2"
            shift 2
            ;;
        -o|--output)
            RESULTS_DIR="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -c|--no-clean)
            CLEAN_FIRST=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -C|--checker-list)
            show_checkers
            ;;
        -k|--keep-going)
            EXIT_ON_ERROR=false
            shift
            ;;
        -V|--view)
            OPEN_RESULTS=true
            shift
            ;;
        *)
            echo -e "${RED}Error:${RESET} Unknown option '$1'"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Check if scan-build is available
if ! command -v scan-build &> /dev/null; then
    echo -e "${RED}Error:${RESET} scan-build command not found"
    echo "Please install clang static analyzer tools:"
    echo "  Debian/Ubuntu: sudo apt install clang-tools"
    echo "  Fedora:        sudo dnf install clang-analyzer"
    echo "  macOS:         brew install llvm"
    exit 1
fi

# Create checker string
CHECKER_STRING=$(IFS=, ; echo "${CHECKERS[*]}")

# Determine analyzer path
ANALYZER_PATH=$(which clang 2>/dev/null)
if [ -z "$ANALYZER_PATH" ]; then
    echo -e "${YELLOW}Warning:${RESET} clang executable not found, using default analyzer"
else
    ANALYZER_ARGS="--use-analyzer=$ANALYZER_PATH"
fi

# Print run information
echo -e "${BOLD}Running Advanced C Code Analysis${RESET}"
echo -e "${BLUE}Project:${RESET} $PROJECT_NAME"
echo -e "${BLUE}Build command:${RESET} $BUILD_CMD"
echo -e "${BLUE}Results directory:${RESET} $RESULTS_DIR"
echo -e "${BLUE}Parallel jobs:${RESET} $JOBS"
echo -e "${BLUE}Enabled checkers:${RESET} ${#CHECKERS[@]}"

if $VERBOSE; then
    echo -e "\n${BOLD}Checkers:${RESET}"
    for checker in "${CHECKERS[@]}"; do
        echo "  - $checker"
    done
fi

echo -e "\n${BOLD}Starting analysis...${RESET}"

# Clean first if requested
if $CLEAN_FIRST; then
    echo -e "${BLUE}→ Cleaning project${RESET}"
    if [[ "$BUILD_CMD" == "make"* ]]; then
        make clean
    elif [[ "$BUILD_CMD" == *"cmake"* ]]; then
        cmake --build . --target clean
    else
        echo -e "${YELLOW}Warning:${RESET} Don't know how to clean this project type"
        echo "Consider running a clean step manually before analysis"
    fi
fi

# Prepare scan-build command
SCAN_CMD=(
    scan-build
    $ANALYZER_ARGS
    --status-bugs
    --keep-going
    -o "$RESULTS_DIR"
    -j "$JOBS"
    --enable-checker "$CHECKER_STRING"
)

# Add extra args from environment if present
if [ -n "$SCAN_BUILD_EXTRA_ARGS" ]; then
    # Split the extra args string into an array
    read -ra EXTRA_ARGS <<< "$SCAN_BUILD_EXTRA_ARGS"
    SCAN_CMD+=("${EXTRA_ARGS[@]}")
fi

# Add verbosity flag if requested
if $VERBOSE; then
    SCAN_CMD+=(-v)
fi

# Add view flag if requested
if $OPEN_RESULTS; then
    SCAN_CMD+=(-V)
fi

# Add build command
read -ra BUILD_CMD_ARRAY <<< "$BUILD_CMD"
SCAN_CMD+=("${BUILD_CMD_ARRAY[@]}")

# Run scan-build
echo -e "${BLUE}→ Running scan-build${RESET}"
if $VERBOSE; then
    echo "Command: ${SCAN_CMD[*]}"
fi

# Run the analysis
"${SCAN_CMD[@]}"
SCAN_EXIT_CODE=$?

# Check if bugs were found
if [ $SCAN_EXIT_CODE -ne 0 ]; then
    echo -e "\n${RED}${BOLD}Warning: scan-build found potential bugs!${RESET}"
    echo -e "Detailed results are available in: ${BOLD}$RESULTS_DIR${RESET}"
    
    if $EXIT_ON_ERROR; then
        exit 1
    fi
else
    echo -e "\n${GREEN}${BOLD}No bugs found by scan-build.${RESET}"
fi

# Print summary
echo -e "\n${BOLD}Analysis Summary:${RESET}"
echo -e "${BLUE}Date:${RESET} $(date)"
echo -e "${BLUE}Results:${RESET} $RESULTS_DIR"
echo -e "${BLUE}Status:${RESET} $([ $SCAN_EXIT_CODE -eq 0 ] && echo "${GREEN}PASSED${RESET}" || echo "${RED}ISSUES FOUND${RESET}")"

echo -e "\n${BOLD}Next steps:${RESET}"
echo "  - Review the HTML report in $RESULTS_DIR"
echo "  - Run with different checkers to find more issues"
echo "  - Fix identified issues and re-run analysis"

exit $SCAN_EXIT_CODE