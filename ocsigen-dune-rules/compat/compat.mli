module Bytesections : sig
  type toc

  val read_toc : in_channel -> toc
  val seek_dbug_section : toc -> in_channel -> int
end
