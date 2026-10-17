with Ada.Streams;
with Ada.Streams.Stream_IO;

package body Bounded_Input is
   procedure Load (File_Name : String; Result : out Bounded_Buffer) is
      use Ada.Streams;
      package Input_IO renames Ada.Streams.Stream_IO;

      File : Input_IO.File_Type;
      Raw  : Stream_Element_Array
        (1 .. Stream_Element_Offset (Maximum_Length + 1));
      Last : Stream_Element_Offset;
   begin
      Result := (Data => [others => ' '], Length => 0);
      Input_IO.Open (File, Input_IO.In_File, File_Name);
      Input_IO.Read (File, Raw, Last);
      Input_IO.Close (File);

      if Last > Stream_Element_Offset (Maximum_Length) then
         raise Constraint_Error with
           "input exceeds the 100-byte bounded buffer";
      end if;

      Result.Length := Valid_Length (Last);
      for Index in 1 .. Result.Length loop
         Result.Data (Index) :=
           Character'Val (Raw (Stream_Element_Offset (Index)));
      end loop;
   exception
      when others =>
         if Input_IO.Is_Open (File) then
            Input_IO.Close (File);
         end if;
         raise;
   end Load;
end Bounded_Input;
