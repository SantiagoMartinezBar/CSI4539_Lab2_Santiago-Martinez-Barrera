with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Bounded_Input;

procedure Safe_Input is
   Input : Bounded_Input.Bounded_Buffer;
begin
   if Ada.Command_Line.Argument_Count /= 1 then
      Ada.Text_IO.Put_Line ("usage: safe_input INPUT_FILE");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Bounded_Input.Load (Ada.Command_Line.Argument (1), Input);
   pragma Assert (Input.Length <= Bounded_Input.Maximum_Length);

   Ada.Text_IO.Put_Line
     ("I accepted" & Input.Length'Image &
      " bytes without writing outside the bounded buffer.");
exception
   when Error : Constraint_Error =>
      Ada.Text_IO.Put_Line
        ("I rejected the input safely: " &
         Ada.Exceptions.Exception_Message (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   when Error : others =>
      Ada.Text_IO.Put_Line
        ("I entered a safe failure state: " &
         Ada.Exceptions.Exception_Message (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Safe_Input;
