import numpy as np

def run_numpy_tests():
    print("Running NumPy Tests...\n")
    
    # 1. Array Creation
    print("1. Array Creation")
    a = np.array([1, 2, 3])
    print("Array a:", a)
    assert (a == [1, 2, 3]).all()

    b = np.zeros((2, 2))
    print("Array b (zeros):\n", b)
    assert (b == [[0, 0], [0, 0]]).all()

    c = np.ones((2, 2))
    print("Array c (ones):\n", c)
    assert (c == [[1, 1], [1, 1]]).all()

    d = np.eye(3)
    print("Array d (identity matrix):\n", d)
    assert (d == [[1, 0, 0], [0, 1, 0], [0, 0, 1]]).all()

    print("Array creation tests passed.\n")

    # 2. Basic Operations
    print("2. Basic Operations")
    x = np.array([1, 2, 3])
    y = np.array([4, 5, 6])
    print("Array x:", x)
    print("Array y:", y)
    print("x + y:", x + y)
    print("x * y:", x * y)
    print("x - y:", x - y)
    print("x / y:", x / y)
    assert (x + y == [5, 7, 9]).all()

    print("Basic operations tests passed.\n")

    # 3. Statistical Functions
    print("3. Statistical Functions")
    stats = np.array([1, 2, 3, 4, 5])
    print("Array stats:", stats)
    print("Mean:", np.mean(stats))
    print("Sum:", np.sum(stats))
    print("Standard Deviation:", np.std(stats))
    assert np.mean(stats) == 3
    assert np.sum(stats) == 15

    print("Statistical functions tests passed.\n")

    # 4. Linear Algebra
    print("4. Linear Algebra")
    matrix1 = np.array([[1, 2], [3, 4]])
    matrix2 = np.array([[2, 0], [1, 2]])
    print("Matrix1:\n", matrix1)
    print("Matrix2:\n", matrix2)

    dot_product = np.dot(matrix1, matrix2)
    print("Dot product:\n", dot_product)
    assert (dot_product == [[4, 4], [10, 8]]).all()

    det = np.linalg.det(matrix1)
    print("Determinant of matrix1:", det)
    assert np.isclose(det, -2.0)

    inv = np.linalg.inv(matrix1)
    print("Inverse of matrix1:\n", inv)
    assert np.allclose(np.dot(matrix1, inv), np.eye(2))

    print("Linear algebra tests passed.\n")

    print("All NumPy tests passed successfully!")

if __name__ == "__main__":
    run_numpy_tests()
