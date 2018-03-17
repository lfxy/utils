#include <iostream>
#include <string>

using namespace std;


string Add(char* num1, char* num2, int length1, int length2) {
    string ret ="";
    int index1 = length1 - 1;
    int index2 = length2 -1;
    int i_tmp = 0;
    while (index1 >= 0 && index2 >= 0){
        int tmp = num1[index1--] - '0' + num2[index2--] - '0';
		tmp += i_tmp;
		i_tmp = tmp / 10;
		tmp = tmp % 10;
		char c_tmp = '0' + tmp;
        ret = c_tmp + ret;
    }
	int last_index = -1;
	char* last_num = NULL;
	if(index1 >= 0) {
		last_index = index1;
		last_num = num1;
	} else if (index2 >= 0) {
		last_index = index2;
		last_num = num2;	
	} else {
		return ret;
	}
    while (last_index >= 0) {
        int tmp = 0;
        if (i_tmp != 0) {
            tmp = last_num[last_index] - '0' + i_tmp;
			i_tmp = tmp / 10;
			tmp = tmp % 10;

			char c_tmp = '0' + tmp;
       	 	ret = c_tmp + ret;
        } else {
            ret = last_num[last_index] + ret;
        }
		last_index--;
    }

    return ret;
}
int main() {
	cout << "hello https://tool.lu/" << endl;
	char a[6] = "41212";
	char b[5] = "2323";
	string ret = Add(a, b, 5, 4);
	cout <<ret <<endl;
	return 0;
}
