import React, { useEffect, useState } from "react";
import { render, Box, Text } from "ink";

const Example = () => {
  const [counter, setCounter] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCounter((counter) => counter + 1);
    }, 100);

    return () => {
      clearInterval(interval);
    };
  }, []);

  return (
    <Box flexDirection="column">
      <Box>
        <Box borderStyle="single" borderColor="green" flexGrow={0}>
          <Text color="green">{counter}</Text>
        </Box>
      </Box>

      <Box>
        <Box borderStyle="single" borderColor="green" flexGrow={0}>
          <Text color="green">{counter}</Text>
        </Box>
      </Box>

      <Box>
        <Box borderStyle="single" borderColor="green" flexGrow={0}>
          <Text color="green">{counter}</Text>
        </Box>
      </Box>
    </Box>
  );
};

render(<Example />);
