#include <algorithm>
#include <functional>
#include <iostream>
#include <limits>
#include <string>
#include <unordered_map>
#include <vector>

struct Term {
  std::string name;
  std::string description;
  int page;
  int line;
  std::string parent;
  std::vector<std::string> subs;

  Term(std::string name, std::string desc, int page, int line,
       std::string parent = "")
      : name(std::move(name)), description(std::move(desc)), page(page),
        line(line), parent(std::move(parent)) {}
};

Term createNewTerm(const std::string &termName = "") {
  std::string name, description, parentName;
  int page, line;

  if (termName.empty()) {
    std::cout << "Введите новое название термина: ";
    std::cin >> name;
    std::cin.ignore(); // игнорируем остаточный символ новой строки
  } else {
    name = termName;
  }

  std::cout << "Введите новое описание термина (введите пустую строку для "
               "завершения): ";
  std::string str;
  while (std::getline(std::cin, str) && !str.empty())
    description += str + "\n";

  std::cout << "Введите новый номер страницы: ";
  std::cin >> page;
  std::cin.ignore(); // игнорируем остаточный символ новой строки

  std::cout << "Введите новый номер строки: ";
  std::cin >> line;
  std::cin.ignore(); // игнорируем остаточный символ новой строки

  std::cout << "Введите новый родительский термин (если есть, иначе оставьте "
               "пустым): ";
  std::getline(std::cin, parentName);

  return Term(name, description, page, line, parentName);
}

class TermIndex {
private:
  std::unordered_map<std::string, Term> hashmap;

  void print(std::ostream &out, const Term &parent,
             std::function<bool(const Term &, const Term &)> sorter,
             int indent = 0) const {
    std::string indentation(indent, ' ');
    out << indentation << parent.name << " (" << parent.page << ":"
        << parent.line << ")\n";

    std::vector<Term> sortedSubs;
    for (const auto &subName : parent.subs) {
      const auto &iter = hashmap.find(subName);
      if (iter != hashmap.end())
        sortedSubs.push_back(iter->second);
    }

    std::sort(sortedSubs.begin(), sortedSubs.end(), sorter);

    for (const Term &term : sortedSubs)
      print(out, term, sorter, indent + 4);
  }

public:
  enum class SortMode { Alphabet, Page };

  void push(const Term &term) {
    hashmap.emplace(term.name, term);
    if (!term.parent.empty()) {
      auto iter = hashmap.find(term.parent);
      if (iter != hashmap.end())
        iter->second.subs.push_back(term.name);
    }
  }

  void pop(const std::string &termName) {
    hashmap.erase(termName);
    for (auto &termPair : hashmap) {
      auto &subTerms = termPair.second.subs;
      subTerms.erase(std::remove(subTerms.begin(), subTerms.end(), termName),
                     subTerms.end());
    }
  }

  void print(std::ostream &out, SortMode type) const {
    std::function<bool(const Term &, const Term &)> sorter;

    switch (type) {
    case SortMode::Alphabet:
      sorter = [](const Term &a, const Term &b) { return a.name < b.name; };
      break;
    case SortMode::Page:
      sorter = [](const Term &a, const Term &b) {
        return a.page == b.page ? a.line < b.line : a.page < b.page;
      };
      break;
    default:
      sorter = [](const Term &a, const Term &b) { return a.name < b.name; };
      break;
    }

    std::vector<Term> topLevelTerms;
    for (const auto &termPair : hashmap) {
      if (termPair.second.parent.empty()) {
        topLevelTerms.push_back(termPair.second);
      }
    }

    std::sort(topLevelTerms.begin(), topLevelTerms.end(), sorter);

    for (const Term &term : topLevelTerms) {
      print(out, term, sorter);
    }
  }

  void updateTerm(const std::string &termName) {
    auto oldTermIter = hashmap.find(termName);
    if (oldTermIter == hashmap.end())
      throw std::invalid_argument("Термин с таким именем не найден.");
    auto oldTerm = oldTermIter->second;
    auto newTerm = createNewTerm(termName);
    newTerm.subs = oldTerm.subs;
    hashmap.erase(termName);
    hashmap.emplace(termName, newTerm);
  }

  void printSingleTerm(std::ostream &out, const std::string &termName) const {
    auto iter = hashmap.find(termName);
    if (iter != hashmap.end()) {
      const Term &term = iter->second;
      if (!term.parent.empty())
        out << term.parent << " / ";
      out << term.name << " (" << term.page << ":" << term.line << ")\n"
          << term.description << "\nПодтермины: ";
      if (term.subs.empty())
        out << "отсутствуют";
      else
        for (const std::string &subTermName : term.subs)
          out << subTermName << ", ";
      out << "\n";
    } else
      out << "Термин с именем '" << termName << "' не найден.\n";
  }

  Term findTermBySubTerm(const std::string &subTermName) const {
    for (const auto &termPair : hashmap) {
      const auto &subTerms = termPair.second.subs;
      if (std::find(subTerms.begin(), subTerms.end(), subTermName) !=
          subTerms.end())
        return termPair.second;
    }
    throw std::invalid_argument("Термин с таким подтермином не найден.");
  }

  std::vector<Term> findSubTermsByTerm(const std::string &termName) const {
    auto iter = hashmap.find(termName);
    if (iter != hashmap.end()) {
      std::vector<Term> subTerms;
      for (const std::string &subTermName : iter->second.subs) {
        auto subTermIter = hashmap.find(subTermName);
        if (subTermIter != hashmap.end())
          subTerms.push_back(subTermIter->second);
      }
      return subTerms;
    }
    return {};
  }
};

void printHelp() {
  std::cout << "\nДоступные действия:\n"
            << "1. Добавить термин\n"
            << "2. Удалить термин\n"
            << "3. Изменить термин\n"
            << "4. Вывести в алфавитном порядке\n"
            << "5. Вывести в страничном порядке\n"
            << "6. Вывести информацию о конкретном термине\n"
            << "7. Найти термин по подтермину\n"
            << "8. Вывести подтермины термина\n"
            << "9. Вывести справку\n"
            << "0. Выйти из программы\n";
}

void handleUserChoice(TermIndex &termIndex, int choice) {
  switch (choice) {
  case 1: {
    Term newTerm = createNewTerm();
    termIndex.push(newTerm);
    std::cout << "Термин успешно добавлен.\n";
    break;
  }
  case 2: {
    std::string termName;
    std::cout << "Введите название термина для удаления: ";
    std::cin >> termName;
    try {
      termIndex.pop(termName);
      std::cout << "Термин успешно удален, если он существовал.\n";
    } catch (const std::exception &e) {
      std::cerr << "Ошибка: " << e.what() << "\n";
    }
    break;
  }
  case 3: {
    std::string termName;
    std::cout << "Введите название термина для изменения: ";
    std::cin >> termName;
    termIndex.updateTerm(termName);
    break;
  }
  case 4: {
    std::cout << "\nСписок всех терминов в алфавитном порядке:\n";
    termIndex.print(std::cout, TermIndex::SortMode::Alphabet);
    break;
  }
  case 5: {
    std::cout << "\nСписок всех терминов в постраничном порядке:\n";
    termIndex.print(std::cout, TermIndex::SortMode::Page);
    break;
  }
  case 6: {
    std::string termName;
    std::cout << "Введите название термина для вывода информации о нем: ";
    std::cin >> termName;
    termIndex.printSingleTerm(std::cout, termName);
    break;
  }
  case 7: {
    std::string subTermName;
    std::cout << "Введите имя подтермина: ";
    std::cin >> subTermName;
    try {
      Term foundTerm = termIndex.findTermBySubTerm(subTermName);
      std::cout << "Найденный термин: " << foundTerm.name << "\n";
    } catch (const std::exception &e) {
      std::cerr << "Ошибка: " << e.what() << "\n";
    }
    break;
  }
  case 8: {
    std::string termName;
    std::cout << "Введите имя термина: ";
    std::cin >> termName;
    std::vector<Term> subTerms = termIndex.findSubTermsByTerm(termName);
    std::cout << "Подтермины термина " << termName << ":\n";
    for (const Term &subTerm : subTerms)
      std::cout << subTerm.name << "\n";
    break;
  }
  case 9: {
    printHelp();
    break;
  }
  case 0: {
    std::cout << "Программа завершена.\n";
    exit(0);
  }
  default: {
    std::cout << "Ошибка: некорректный выбор. Повторите попытку.\n";
  }
  }
}

int main() {
  TermIndex termIndex;

  termIndex.push(Term("Банан", "Описание родительского термина 1", 5, 2));
  termIndex.push(Term("Собака", "Описание родительского термина 2", 2, 1));
  termIndex.push(Term("Апельсин", "Описание подтермина 1", 1, 2, "Банан"));
  termIndex.push(Term("Яблоко", "Описание подтермина 2", 5, 3, "Банан"));
  termIndex.push(Term("Кот", "Описание подтермина 3", 2, 2, "Собака"));
  termIndex.push(Term("Слон", "Описание подтермина 4", 5, 3, "Собака"));
  termIndex.push(
      Term("Крокодил", "Описание подподтермина 1", 2, 4, "Апельсин"));
  termIndex.push(Term("Жираф", "Описание подподтермина 2", 1, 5, "Апельсин"));
  termIndex.push(Term("Лиса", "Описание подподтермина 3", 2, 6, "Яблоко"));
  termIndex.push(Term("Волк", "Описание подподтермина 4", 1, 7, "Яблоко"));
  termIndex.push(Term("Муравей", "Описание подподтермина 5", 3, 8, "Кот"));
  termIndex.push(Term("Пантера", "Описание подподтермина 6", 7, 9, "Кот"));
  termIndex.push(Term("Кенгуру", "Описание подподтермина 7", 4, 10, "Слон"));
  termIndex.push(Term("Лев", "Описание подподтермина 8", 8, 11, "Слон"));

  printHelp();
  while (true)
    try {
      int choice;
      std::cout << "\n>> ";
      std::cin >> choice;
      if (std::cin.fail()) {
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        throw std::invalid_argument(
            "Введено некорректное значение. Повторите попытку.");
      }
      handleUserChoice(termIndex, choice);
    } catch (const std::exception &e) {
      std::cerr << "Ошибка: " << e.what() << "\n";
    }
}
