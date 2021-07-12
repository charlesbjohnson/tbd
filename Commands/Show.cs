using Spectre.Console;
using Spectre.Console.Cli;

namespace TBD
{
    namespace Commands
    {
        public class Show : Command
        {
            public override int Execute(CommandContext context)
            {
                AnsiConsole.MarkupLine("showing");
                return 0;
            }
        }
    }
}
