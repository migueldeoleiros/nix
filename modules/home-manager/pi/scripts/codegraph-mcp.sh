export DO_NOT_TRACK=1
export CODEGRAPH_NO_UPDATE_CHECK=1
exec codegraph serve --mcp "$@"
