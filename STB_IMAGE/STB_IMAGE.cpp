//
//  STB_IMAGE.cpp
//  STB_IMAGE
//
//  Created by van Liempt, Jordi on 27.04.22.
//  Copyright © 2022 Ken Arroyo Ohori. All rights reserved.
//

#include <iostream>
#include "STB_IMAGE.hpp"
#include "STB_IMAGEPriv.hpp"

void STB_IMAGE::HelloWorld(const char * s)
{
    STB_IMAGEPriv *theObj = new STB_IMAGEPriv;
    theObj->HelloWorldPriv(s);
    delete theObj;
};

void STB_IMAGEPriv::HelloWorldPriv(const char * s) 
{
    std::cout << s << std::endl;
};

