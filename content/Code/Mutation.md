---
title: "Mutation"
date: 2015-03-23T22:59:49+02:00
draft: true
comments: false
images:
---

Mutation est un programme qui calcule le gène gagant parmit N gènes.

Il y a N gènes, admettons par exemple qu'il y en a 100.

Chaque gène a donc 1% de chance d'être selectionné et d'être "sauvegardé" pour une prochaine génération de calcule. Plus le gène X est sauvegardé, plus il a de chance d'être tiré à la prochaine génération et donc d'être encore plus présent au fil des génération. C'est ce que l'on appel la mutation génétique.

La dernière génération est quand il ne reste plus qu'un gène, le gène qui a était le plus sauvegarder par génération.

## Image 

![](/img/mutation.png)

## Code

```cpp
#include <iostream>
#include <chrono>
#include <cassert>
#include <cstdint>
#include <vector>
#include <random>

// Tutoriel pratique d'un ami, Piticroissant: http://piticroissant.wordpress.com/2014/04/19/bien-generer-les-nombres-pseudo-aleatoires/
template <typename T>
T random(const T& min, const T& max)
{
    static_assert(std::is_arithmetic<T>::value,
            "random() needs arithmetic type");

    static std::random_device rd;
    static std::mt19937 gen{rd()};

    return typename std::conditional<
            std::is_integral<T>::value,
            std::uniform_int_distribution<T>,
            std::uniform_real_distribution<T>>::type{min, max}(gen);
}

class Mutation {
public:
    Mutation() {

    }

    ~Mutation() {
        m_individuID.clear();
        m_listIndividu.clear();
    }

    void	setIndividu(uint32_t nindividu) {
        std::cout << "ID de dÃ©part: ";

        for(auto i = 0; i < nindividu; ++i) {
            m_individuID.push_back(i);
            std::cout << m_individuID.at(i) << " ";
        }

        assert(!m_individuID.empty());

        std::cout << std::endl;
    }


    void	processMutation() {
        uint32_t    totalGeneration = 1;
        bool        winner = false;

        auto timeBegin = std::chrono::system_clock::now();

        while(!winner) {
            nextGeneration();
            ++totalGeneration;

            if(verifWin()) {
                winner = true;
            }
        }

        auto timeEnd = std::chrono::system_clock::now();

        std::chrono::duration<double> result = (timeEnd - timeBegin);

        std::cout << "Mutation gagnante " << m_individuWinner << " en " << totalGeneration << " gÃ©nÃ©rations (" << result.count() << "s)";
    }

private:
    void 	nextGeneration() {
        for(auto actindividu = 0; actindividu < m_individuID.size(); ++actindividu) {
            int chance = random(0, static_cast<int>(m_individuID.size()));

            for(int i = 0; i < chance; ++i) {
                m_listIndividu.push_back(m_individuID.at(actindividu));
            }
        }

        for(int i = 0; i <  m_individuID.size(); ++i) {
            int here = random(0, static_cast<int>(m_listIndividu.size() - 1));

            m_individuID.at(i) = m_listIndividu.at(here);

            std::cout << m_individuID.at(i) << " ";
        }

        std::cout << std::endl;

        m_listIndividu.clear();
    }

    bool    	verifWin() {
        auto    tmp = m_individuID.at(0);
        auto    max = m_individuID.size();

        for(int i = 1; i < max; ++i) {
            if(m_individuID.at(i) == tmp) {
                m_individuWinner = m_individuID.at(i);
                return true;
            }
            else {
                return false;
            }
        }
    }

private:
    uint32_t                m_individuWinner;

    std::vector<uint32_t>   m_listIndividu;
    std::vector<uint32_t>   m_individuID;
};

int main(int argc, char *argv[]) {

    Mutation mutation;

    uint32_t	nindividu;

    std::cout << "Nombre d'individus: ";
    std::cin >> nindividu;

    mutation.setIndividu(nindividu);

    std::cout << std::endl;

    mutation.processMutation();

    return 0;
}
```
