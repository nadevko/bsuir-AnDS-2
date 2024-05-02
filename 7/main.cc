#include <cctype>
#include <format>
#include <iostream>
#include <map>
#include <stack>
#include <stdexcept>
#include <string>

using namespace std;

enum precedence { operand, open, close, sum, multiply, power };
map<char, precedence> precmap = {
    {'(', open},     {')', close},    {'+', sum},      {'-', sum},
    {'*', multiply}, {'/', multiply}, {'%', multiply}, {'^', power}};
using entry = pair<string, precedence>;

string mkBracked(entry entry, precedence current) {
  bool isBracked = entry.second < current && entry.second != operand;
  return (isBracked ? "(" : "") + entry.first + (isBracked ? ")" : "");
}

string to_infix(string input) {
  stack<entry> stack;
  string digit;
  for (auto c : input)
    if (precmap[c] == operand)
      if (isspace(c)) {
        if (!digit.empty())
          stack.push(pair(digit, operand));
        digit.clear();
      } else if (!isdigit(c) && c != '.')
        throw runtime_error(format("Операция {} не определена", c));
      else if (c == '.' && digit.find('.') != string::npos)
        throw runtime_error(format("Два разделителя в числе", c));
      else
        digit += c;
    else if (stack.size() < 2)
      throw runtime_error("Недостаточно операндов");
    else {
      auto i = stack.top();
      stack.pop();
      auto j = stack.top();
      stack.pop();
      auto current = precmap[c];
      stack.push(
          pair(mkBracked(j, current) + c + mkBracked(i, current), current));
    }
  if (!stack.empty())
    throw runtime_error("Недостаточно операторов");
  return stack.top().first;
}

int main() {
  cout << "Введите постфиксное выражение: ";
  string input;
  getline(cin, input);
  try {
    auto result = to_infix(input);
    cout << "Результат: " << result << endl;
  } catch (runtime_error &err) {
    cout << "Ошибка: " << err.what() << endl;
  }
}
