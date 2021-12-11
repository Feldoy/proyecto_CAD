// C++ implementation of the approach
#include <bits/stdc++.h>
using namespace std;

// Function to print the intersection
void findIntersection(int intervals[][2], int N)
{
	// First interval
	int l = intervals[0][0];
	int r = intervals[0][1];

	// Check rest of the intervals and find the intersection
	for (int i = 1; i < N; i++) {

		// If no intersection exists
		if (intervals[i][0] > r || intervals[i][1] < l) {
			cout << -1;
			return;
		}

		// Else update the intersection
		else {
			l = max(l, intervals[i][0]);
			r = min(r, intervals[i][1]);
		}
	}

	cout << "[" << l << ", " << r << "]";
}

// Driver code
int main()
{
	int intervals[][2] = {
		{ 1, 6 },
		{ 2, 8 },
		{ 3, 10 },
		{ 5, 8 }
	};
	int N = sizeof(intervals) / sizeof(intervals[0]);
	findIntersection(intervals, N);
}

/*
for i en el largo de A
    for j in el largo de B

    Si A[i] se intersecta con B[j]
        Guardar (i,j)
*/
