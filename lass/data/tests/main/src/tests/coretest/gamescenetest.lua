local lass = require("lass")
local turtlemode = require("turtlemode")
local helpers = require("tests.coretest.helpers")
local GameEntityTest = require("tests.coretest.gameentitytest")
local assertLen, assertEqual = turtlemode.assertLen, turtlemode.assertEqual

local GameSceneTest = turtlemode.testModule()

function GameSceneTest:createEntity(scene, name, transform, parent)
    return lass.GameScene(transform, parent)
end

function GameSceneTest.fixtures.scene(self)
    return lass.GameScene()
end

function GameSceneTest:testChildrenAndGameObjects(scene)

    assertLen(scene.gameObjects, 0)

    local object = lass.GameObject(scene, "test")
    assertLen(scene.gameObjects, 1)
    assertEqual(helpers.numTreeNodes(scene), 1)

    local child = lass.GameObject(scene, "test child")
    object:addChild(child)
    assertLen(scene.gameObjects, 2)
    assertEqual(helpers.numTreeNodes(scene), 2)

    local grandchild = lass.GameObject(scene, "test grandchild")
    child:addChild(grandchild)
    assertLen(scene.gameObjects, 3)
    assertEqual(helpers.numTreeNodes(scene), 3)

    local object2 = lass.GameObject(scene, "test 2")
    assertLen(scene.gameObjects, 4)
    assertEqual(helpers.numTreeNodes(scene), 4)
end

return GameSceneTest