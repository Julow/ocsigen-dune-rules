module Bytesections = struct
  type toc = Bytesections.section_table

  let read_toc ic = Bytesections.read_toc ic

  let seek_dbug_section toc ic =
    Bytesections.seek_section toc ic Bytesections.Name.DBUG
end
