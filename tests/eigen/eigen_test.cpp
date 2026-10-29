#include <Eigen/Dense>
#include <cstdio>

int main()
{
    Eigen::Matrix3d a;
    a << 2, 1, 1,
         1, 3, 0,
         1, 2, 0;
    Eigen::Vector3d b(4, 5, 6);
    Eigen::Vector3d x = a.colPivHouseholderQr().solve(b);
    std::printf("x = %.5f %.5f %.5f\n", x(0), x(1), x(2));

    Eigen::Matrix3d s;
    s <<  2, -1,  0,
         -1,  2, -1,
          0, -1,  2;
    Eigen::SelfAdjointEigenSolver<Eigen::Matrix3d> es(s);
    Eigen::Vector3d w = es.eigenvalues();
    std::printf("eigenvalues = %.5f %.5f %.5f\n", w(0), w(1), w(2));
    std::printf("Eigen %d.%d.%d\n", EIGEN_WORLD_VERSION, EIGEN_MAJOR_VERSION, EIGEN_MINOR_VERSION);
    return 0;
}
