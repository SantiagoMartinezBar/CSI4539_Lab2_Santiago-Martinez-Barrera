package Bounded_Input is
   Maximum_Length : constant := 100;

   subtype Buffer_Index is Positive range 1 .. Maximum_Length;
   subtype Valid_Length is Natural range 0 .. Maximum_Length;

   type Bounded_Buffer is record
      Data   : String (Buffer_Index) := (others => ' ');
      Length : Valid_Length := 0;
   end record;

   procedure Load (File_Name : String; Result : out Bounded_Buffer)
     with Post => Result.Length <= Maximum_Length;
end Bounded_Input;
