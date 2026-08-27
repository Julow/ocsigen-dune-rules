module Bytesections = struct
  type toc = unit

  let read_toc ic = ignore (Bytesections.read_toc ic)
  let seek_dbug_section () ic = Bytesections.seek_section ic "DBUG"
end
