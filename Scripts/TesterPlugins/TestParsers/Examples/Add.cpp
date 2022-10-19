// This is a useless class here to provide class-based code coverage info
class Adder {
public:
    int Add(int a, int b) {
        return a + b;
    }

    int MethodIsNeverCalled() {
        return 10;
    }
};

int Add(int a, int b) {
    return Adder().Add(a, b); // See comments above
}

int IsNotCalled(int a, int b) {
    return a + b;
}

namespace Namespace {
    int NamespaceMethod() {
        return 1;
    }
}
