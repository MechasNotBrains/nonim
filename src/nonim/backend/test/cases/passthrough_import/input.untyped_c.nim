{.emit[declaration]: "#pragma GCC diagnostic push".}
import @stdint.h
{.emit[declaration]: "#pragma GCC diagnostic pop".}
{.emit[declaration, definition]: "#define VALUE 1".}
{.emit: "int value = VALUE;".}
