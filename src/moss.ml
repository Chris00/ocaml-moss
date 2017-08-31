(* File: moss.ml

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

open Printf
(* open Lwt *)

type lang =
  | C | CC | Java | Ml | Pascal | Ada | Lisp | Scheme | Haskell
  | Fortran | Ascii | Vhdl | Perl | Matlab | Python | Mips | Prolog
  | Spice | VB | Csharp | Modula2 | A8086 | Javascript | Plsql

let string_of_lang = function
  | C -> "c"
  | CC -> "cc"
  | Java -> "java"
  | Ml -> "ml"
  | Pascal -> "pascal"
  | Ada -> "ada"
  | Lisp -> "lisp"
  | Scheme -> "scheme"
  | Haskell -> "haskell"
  | Fortran -> "fortran"
  | Ascii -> "ascii"
  | Vhdl -> "vhdl"
  | Perl -> "perl"
  | Matlab -> "matlab"
  | Python -> "python"
  | Mips -> "mips"
  | Prolog -> "prolog"
  | Spice -> "spice"
  | VB -> "vb"
  | Csharp -> "csharp"
  | Modula2 -> "modula2"
  | A8086 -> "a8086"
  | Javascript -> "javascript"
  | Plsql -> "plsql"

let server = "moss.stanford.edu"
let server_ip = Unix.inet_addr_of_string "171.64.78.49"
let port = 7690
let server_addr =
  try
    let h = Unix.gethostbyname server in
    Unix.ADDR_INET(h.Unix.h_addr_list.(0), port)
  with _ ->
    Unix.ADDR_INET(server_ip, port) (* fallback *)

(* userid seem to be of the type "[0-9]+".  However, we do not have
   guarantees about them, they could start with 0 or exceed the
   capacity of native integers (Perl can store numbers as "decimal
   strings"). *)
let check_userid ~err id =
  for i = 0 to String.length id - 1 do
    if id.[i] < '0' || '9' < id.[i] then invalid_arg err
  done

let default_userid =
  ref(try let id = Sys.getenv "MOSS_USERID" in
          check_userid id ~err:"The shell variable MOSS_USERID should only \
                                be made of digits 0-9.";
          id
      with Not_found -> "0")

let set_userid id =
  check_userid id ~err:"Moss.set_userid: the userid must only be \
                        made of digits 0-9";
  default_userid := id

let get_userid () = !default_userid

(* [id] = 0 ⇒ base file *)
let upload_file out_fh filename ~id ~lang =
  let st = Unix.stat filename in
  fprintf out_fh "file %d %s %d %s\n" id lang st.Unix.st_size filename;
  let b = Bytes.create 4096 in
  let in_fh = open_in filename in
  let len = ref 0 in
  while len := input in_fh b 0 4096;  !len > 0 do
    output out_fh b 0 !len;
  done;
  close_in in_fh


let submit ?(userid= !default_userid) ?(experimental=false) ?comment
      ?(by_dir=false) ?(max_rep=10) ?(n=250) lang ?(base=[]) files =
  check_userid userid ~err:"Moss.submit: userid must only be made of \
                            digits 0-9";
  let by_dir = if by_dir then '1' else '0' in
  let experimental = if experimental then '1' else '0' in
  if max_rep < 2 then invalid_arg "Moss.submit: ~max_rep must be >= 2";
  if n < 2 then invalid_arg "Moss.submit: ~n must be >= 2";
  let lang = string_of_lang lang in
  let comment = match comment with
    | Some c ->
       for i = 0 to String.length c - 1 do
         if c.[i] < ' ' || c.[i] > '}' then
           failwith "Moss.submit: comment can only contain printable \
                     ASCII characters"
       done;
       c
    | None -> "" in
  let in_fh, out_fh = Unix.open_connection server_addr in
  let close_sock () =
    output_string out_fh "end\n";
    flush out_fh;
    Unix.shutdown_connection in_fh in
  (* FIXME: Do we want to introduce timeouts? *)
  fprintf out_fh "moss %s\ndirectory %c\nX %c\nmaxmatches %d\nshow %d\n\
                  language %s\n%!"
    userid by_dir experimental max_rep n lang;
  let r = input_line in_fh in
  if r = "no" then (
    close_sock ();
    failwith ("Moos.connect: unrecognized language " ^ lang);
  );
  (* Upload any base file. *)
  List.iter (fun fn -> upload_file out_fh fn ~id:0 ~lang) base;
  (* Upload other files. *)
  List.iteri (fun i fn -> upload_file out_fh fn ~id:(i+1) ~lang) files;
  fprintf out_fh "query 0 %s\n%!" comment;
  let r, _, _ = Unix.select [Unix.descr_of_in_channel in_fh] [] [] 1. in
  match r with
  | [] -> close_sock();
          failwith "timeout"
  | _ :: _ ->
     let url = input_line in_fh in
     close_sock();
     Uri.of_string url

;;
(* Local Variables: *)
(* compile-command: "make -k -C.. build" *)
(* End: *)
