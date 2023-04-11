function dbgPrint(msg)
global dbgPrint dbgPrintFileId
if dbgPrint
    fprintf(dbgPrintFileId, [msg '\n']);
end
end