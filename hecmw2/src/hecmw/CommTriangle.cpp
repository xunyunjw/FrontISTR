
#include <vector>

//
//  CommTriangle.cpp
//
//
//
//                  2009.09.10
//                  2009.09.10
//                  k.Takeda
#include "CommTriangle.h"
using namespace pmw;

// construct & destruct
//
CCommTriangle::CCommTriangle()
{
    //// prolongation-Comm要素
    //mvProgCommElem.reserve(3);

    // Node rank
    mvNodeRank.resize(3);
    mvEdgeRank.resize(3);
    mvFaceRank.resize(1);

    mvbSend = new bool[3];
    mvbRecv = new bool[3];
    mvbOther = new bool[3];

    mvbNodeIXCheck = new bool[3];
    mvbDNodeMarking = new bool[3];
    uiint i;
    for(i=0; i< 3; i++){
        mvbNodeIXCheck[i]=false;
        mvbDNodeMarking[i]=false;

        mvbSend[i]=false;
        mvbRecv[i]=false;
        mvbOther[i]=false;
    }

    // 頂点別の要素集合
    mvvAggCommElem.resize(3);
    mvvNeibCommElemVert.resize(3);

    // CommMesh内のグローバルIndex
    mvCommNodeIndex.resize(3);
}

CCommTriangle::~CCommTriangle()
{
    ;
}

// debug method :所有しているElementの型が一致するか？
//
bool CCommTriangle::isTypeCoincidence()
{
    bool bCoin(false);

    if(mpElement->getType()==ElementType::Triangle) bCoin=true;

    return bCoin;
}























