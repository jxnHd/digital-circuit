#include "Neuron.h"

void Neuron::neuron() {
	output_temp = input1.read()*w1+input2.read()*w2+b;
	if (output_temp<=0)
	{
		output_temp = 0;
		output.write(output_temp);
	}
	else
	{
		output.write(output_temp);
	}


}

