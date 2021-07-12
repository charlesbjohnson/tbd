using Spectre.Console.Cli;

namespace TBD
{
    class Program
    {
        static int Main(string[] args)
        {
            var app = new CommandApp();

            // SHOW
            // cat notes.otln | tbd show
            //
            // ADDITION
            // cat notes.otln | tbd add .0 --before  "before 0, new note"
            // cat notes.otln | tbd add .0 --after   "after 0, new note"
            // cat notes.otln | tbd add .0 --prepend "child of 0, start of children, new note"
            // cat notes.otln | tbd add .0 --append  "child of 0, end of children, new note"
            //
            // EDITING
            // cat notes.otln | tbd edit .0 "at 0, change note"
            //
            // MOVEMENT
            // cat notes.otln | tbd move .0 --before  .1
            // cat notes.otln | tbd move .0 --after   .1
            // cat notes.otln | tbd move .0 --prepend .1
            // cat notes.otln | tbd move .0 --append  .1
            //
            // DELETION
            // cat notes.otln | tbd delete .0
            app.Configure(config =>
            {
                config.AddCommand<Commands.Show>("show");
            });

            return app.Run(args);
        }
    }
}
