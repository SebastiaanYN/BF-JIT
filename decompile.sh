if [ -f "jit.out" ]; then
    objdump -b binary -D -m i386:x86-64 jit.out
else
    echo "jit.out does not exist. Run a program in debug mode"
fi
