#include <cmath>
#include <functional>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;

const size_t LIMIT = 2000;

template <typename K, typename T, size_t LIMIT = LIMIT> class HashMap {
public:
  struct Node {
    Node() {}
    Node(K key, T value) : key(key), value(value) {}
    K key;
    T value;
    Node *next = nullptr;

    size_t count() { return (next == nullptr) ? 1 : 1 + next->count(); }

    void insert(Node &node) {
      if (key == node.key)
        value = node.value;
      else if (next == nullptr)
        next = &node;
      else
        next->insert(node);
    }

    void update(function<T(T &)> lambda) { value = lambda(&value); }

    Node *erase(K _key) {
      if (key == _key)
        return next;
      else if (next != nullptr)
        next = next->erase(_key);
      return this;
    }

    T *find(K _key) {
      return (key == _key)       ? &value
             : (next == nullptr) ? nullptr
                                 : next->find(_key);
    }
  };

  struct Iterator {
    using difference_type = ptrdiff_t;
    using element_type = Node *;
    using pointer = element_type *;
    using reference = element_type &;

  private:
    pointer ptr, start, stop;
    static_assert(sentinel_for<decltype(stop), decltype(ptr)>);

  public:
    Iterator() {}
    Iterator(pointer p, pointer s) : ptr(p), start(p), stop(s) {}
    reference operator*() const { return *ptr; }

    Iterator &operator++() {
      ++ptr;
      return *this;
    }
    Iterator operator++(int) {
      auto temp = *this;
      ++*this;
      return temp;
    }

    auto operator<=>(const Iterator &rhs) const = default;
    auto begin() { return start; }
    auto end() { return stop; }
  };
  auto begin() { return iter.begin(); }
  auto end() { return iter.end(); }

  void insert(Node &node) {
    auto key = hash<K>{}(node.key);
    if (memory[key] == nullptr)
      memory[key] = &node;
    else
      memory[key]->insert(node);
  }
  void insert(K key, T value) { insert(*new Node{key, value}); }

  void erase(K key) {
    auto index = hash<K>{}(key);
    if (memory[index] == nullptr)
      return;
    memory[index] = memory[index]->erase(key);
  }

  T *find(K key) const {
    auto index = hash<K>{}(key);
    return (memory[index] == nullptr) ? nullptr : memory[index]->find(key);
  }
  T *operator[](K key) const { return find(key); }

private:
  Node *memory[LIMIT] = {};
  static_assert(forward_iterator<Iterator>);
  Iterator iter = Iterator(memory, std::end(memory));
};

template <> struct std::hash<string> {
  size_t operator()(const string &key) const noexcept {
    size_t result = 0;
    for (size_t i = 1; i <= key.length(); i++)
      result += pow(key[i - 1], 2) / 3 / i;
    return static_cast<size_t>(pow(result, 2)) / 100 % LIMIT;
  }
};

struct term {
  string title;
  string description;
  string parent;
  uint page;
  uint line;
};

void helpMe() {
  cout << "  .    Вывести термин\n"
          "  :    Вывести термины\n"
          "  +    Добавить/изменить термин\n"
          "  -    Удалить термин\n"
          "  а    Отсортировать по алфавиту\n"
          "  н    Отсортировать по номерам страниц\n"
          "  т    Найти термин по подтермину\n"
          "  п    Найти подтермины по термину\n"
          "  _    Выйти\n"
          "  ?    Вывести это сообщение помощи\n";
}

template <typename T> T readstoi(string prompt = "") {
  string input;
  try {
    cout << prompt;
    getline(cin, input);
    return static_cast<T>(stoi(input));
  } catch (const invalid_argument &) {
    cout << "Попробуйте снова\n";
    return readstoi<T>(prompt);
  }
}

int main() {
  HashMap<string, term> map;
  helpMe();
  string input;
  while (true) {
    cout << ">> ";
    getline(cin, input);
    try {
      if (input == ".") {
        cout << "Термин: ";
        getline(cin, input);
        auto term = map[input];
        if (term == nullptr)
          throw runtime_error("Термин не найден");
        cout << "\nОписание:\n"
             << term->description << "Родительский термин: " << term->parent
             << "\nСтраница: " << term->page << "\nСтрока: " << term->line
             << endl;
      } else if (input == ":") {
        for (auto i : map)
          if (i != nullptr)
            for (; i != nullptr; i = i->next)
              cout << i->key << endl;
      } else if (input == "+") {
        term t;
        cout << "Термин: ";
        getline(cin, t.title);
        cout << "Описание:\n";
        while (getline(cin, input) && !input.empty())
          t.description += input + "\n";
        cout << "Родительский термин: ";
        getline(cin, t.parent);
        t.page = readstoi<uint>("Страница: ");
        t.line = readstoi<uint>("Строка: ");
        map.insert(t.title, t);
      } else if (input == "-") {
        cout << "Термин: ";
        getline(cin, input);
        map.erase(input);
      } else if (input == "а") {
        vector<HashMap<string, term>::Node> terms;
        for (auto i : map)
          if (i != nullptr)
            for (; i != nullptr; i = i->next)
              terms.push_back(*i);
        sort(terms.begin(), terms.end(),
             [](auto a, auto b) { return a.key < b.key; });
        for (auto i : terms)
          cout << i.key << endl;
      } else if (input == "н") {
        vector<HashMap<string, term>::Node> terms;
        for (auto i : map)
          if (i != nullptr)
            for (; i != nullptr; i = i->next)
              terms.push_back(*i);
        sort(terms.begin(), terms.end(),
             [](auto a, auto b) { return a.value.page < b.value.page; });
        for (auto i : terms)
          cout << i.key << endl;
      } else if (input == "т") {
        cout << "Подтермин: ";
        getline(cin, input);
        auto subterm = map[input];
        if (subterm == nullptr)
          throw runtime_error("Подтермин не найден");
        cout << subterm->parent << endl;
      } else if (input == "п") {
        cout << "Термин: ";
        getline(cin, input);
        for (auto i : map)
          if (i != nullptr)
            for (; i != nullptr; i = i->next)
              if (i->value.parent == input)
                cout << i->key << endl;
      } else if (input == "_") {
        return 0;
      } else if (input == "?")
        helpMe();
      else
        throw runtime_error("Такой команды нет");
    } catch (const runtime_error &err) {
      cout << "Ошибка: " << err.what() << endl;
    }
  }
}
