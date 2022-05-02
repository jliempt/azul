//
//  GLAD.cpp
//  GLAD
//
//  Created by van Liempt, Jordi on 27.04.22.
//  Copyright © 2022 Ken Arroyo Ohori. All rights reserved.
//

#include <iostream>
#include "GLAD.hpp"
#include "GLADPriv.hpp"

void GLAD::HelloWorld(const char * s)
{
    GLADPriv *theObj = new GLADPriv;
    theObj->HelloWorldPriv(s);
    delete theObj;
};

void GLADPriv::HelloWorldPriv(const char * s) 
{
    std::cout << s << std::endl;
};

