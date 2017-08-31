(* File: moss.mli

   Copyright (C) 2017-

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   Permission to use, copy, modify, and/or distribute this software
   for any purpose with or without fee is hereby granted, provided
   that the above copyright notice and this permission notice appear
   in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
   WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
   AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
   CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
   OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
   NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
   CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  *)

(** Client for the MOSS plagiarism detection service.

    @version %%VERSION%% *)


(** Source language of programs being tested. *)
type lang =
  | C | CC | Java | Ml | Pascal | Ada | Lisp | Scheme | Haskell
  | Fortran | Ascii | Vhdl | Perl | Matlab | Python | Mips | Prolog
  | Spice | VB | Csharp | Modula2 | A8086 | Javascript | Plsql


val set_userid : string -> unit
(** [set_userid id] the the default user ID.  Use the one that was
   sent to you when you {{:http://theory.stanford.edu/~aiken/moss/}asked
   for an account}.  The default userid is set from the environment
   variable MOSS_USERID or else is ["0"]. *)

val get_userid : unit -> string
(** Return the default userid. *)


val submit : ?userid: string -> ?experimental: bool -> ?comment: string ->
             ?by_dir: bool -> ?max_rep: int -> ?n: int -> lang ->
             ?base: string list -> string list -> Uri.t
(** [submit lang filenames] submit the files whose relative paths are
   given in [filenames] and return the result from MOSS.

   @param base Moss normally reports all code that matches in pairs of
   files.  When base files are supplied, program code that also
   appears in any base file is not counted in matches.  A typical base
   file will include, for example, the instructor-supplied code for an
   assignment.  You should use base files if it is convenient; base
   files improve results, but are not usually necessary for obtaining
   useful information.

   @param by_dir specifies that submissions are by directory, not by
   file.  That is, files in a directory are taken to be part of the
   same program, and reported matches are organized accordingly by
   directory.  Default: [false].

   @param n determines the number of matching files to show in the
   results.  The default is [250].

   @param max_rep sets the maximum number of times a given passage may
   appear before it is ignored.  A passage of code that appears in
   many programs is probably legitimate sharing and not the result of
   plagiarism.  With [~max_rep], any passage appearing in more than
   [max_rep] programs is treated as if it appeared in a base file
   (i.e., it is never reported).  With [~max_rep:2], moss reports only
   passages that appear in exactly two programs.  If one expects many
   very similar solutions (e.g., the short first assignments typical
   of introductory programming courses) then using [~max_rep:3] or
   [~max_rep:4] is a good way to eliminate all but truly unusual
   matches between programs while still being able to detect 3-way or
   4-way plagiarism.  With [~max_rep:1000000] (or any very large
   number), moss reports all matches, no matter how often they appear.
   The [~max_rep] setting is most useful for large assignments where
   one also a base file expected to hold all legitimately shared code.
   The default for [~max_rep] is [10].

   @param experimental sends queries to the current experimental
   version of the server.  The experimental server has the most recent
   Moss features and is also usually less stable (read: may have more
   bugs).  Default: [false].

   @param userid override the default userid (see {!set_userid}). *)

;;
