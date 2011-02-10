//
//  heath.cpp
//  DOPSIM
//
//  Created by Joshua Weinberg on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include <vector>

using namespace std;

int main()
{
	double alpha = 1.0;
	double a = 0.001; //.mm
	double h = 1; //.minutes
	int n = 10;
	int n_timesteps = 100;
	vector<double> u(n);
	vector<double> v(n);
	for (int i = 0; i < n; ++i)
		u[i] = (i==0)?200:0;
	
	for (int t = 0; t < n_timesteps; ++t)
	{
		// u(x,t+h) = alpha*h/a^2 (u(x+a,t)-2u(x,t)+u(x-a,t)) + u(x,t)
		// v(x) = alpha*h/a^2 (u(x+a)-2u(x)+u(x-a)) + u(x)
		// v[x] = alpha*h/a^2 (u[i+1]-2u[i]+u[i-1]) + u[i]
		for (int i = 1; i < n-1; ++i)
		{
			v[i] = alpha*h/(a*a)*(u[i+1]-2.0*u[i]+u[i-1]) + u[i];
		}
		for (int i = 1; i < n-1; ++i)
			u[i] = v[i];
		printf("%d) middle T=%f\n", t, u[n/2]);
	}
		
	return 0;
}